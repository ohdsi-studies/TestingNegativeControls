setwd('D:\\')
# This script is used once to initialize your project

# Make sure the necessary packages are installed
dynamic_require <- function(...){
  origVal <- getOption("install.packages.compile.from.source")
  options(install.packages.compile.from.source = "never")
  on.exit(options(install.packages.compile.from.source = origVal))
  libs<-unlist(list(...))
  for (package in libs) {
    remotePackage <- grepl("/", package)
    packageRef <- grepl("@", package)
    packageRoot <- ifelse(remotePackage, strsplit(x = package, "/")[[1]][2], package)
    packageRoot <- ifelse(packageRef, strsplit(x = packageRoot, "@")[[1]][1], packageRoot)
    packageRef <- ifelse(packageRef, strsplit(x = package, "@")[[1]][2], "HEAD")
    if(eval(parse(text=paste("require(",packageRoot,")"))) == FALSE) {
      message(paste0("Installing: ", package))
      if (remotePackage) {
        remotes::install_github(repo = package, ref = packageRef)
      } else {
        install.packages(package)
      }
    }
  }
}
dynamic_require(
  "remotes",
  "usethis",
  "config",
  "dplyr",
  "readr",
  "ohdsi/DatabaseConnector",
  "ohdsi/FeatureExtraction",
  "ohdsi/ParallelLogger",
  "ohdsi/SqlRender",
  "ohdsi/ROhdsiWebApi",
  "ohdsi/Strategus",
  "ohdsi/PheValuator",
  "ohdsi/ResultModelManager",
  "ohdsi/CohortDiagnostics@v3.1.2",
  "ohdsi/CohortGenerator@v0.8.0",
  "ohdsi/Characterization@v0.1.1",
  "ohdsi/CohortIncidence@v3.1.2",
  "ohdsi/CohortMethod@74f017107e0cc1b740a2badc82879ab6ad291b23",
  "ohdsi/SelfControlledCaseSeries@15918616814b88137f82bf2aa9986e1dcdf39e74",
  "ohdsi/PatientLevelPrediction@v6.3.1",
  "ohdsi/ShinyAppBuilder@develop",
  "ohdsi/OhdsiShinyModules@develop"
)


# Check to ensure the default keyring is set up
config <- config::get()
if (!config$keyringName %in% keyring::keyring_list()$keyring) {
  stop("You need to set up your keyring.")
}

# Check to make sure environment variable is set for keyring password so 
# it may be unlocked if required.
if (Sys.getenv("STRATEGUS_KEYRING_PASSWORD") == "") {
  stop("You need to set the keyring password in your .Renviron file. To do this:
        - Run `usethis::edit_r_environ()` to open your .Renviron file
        - Add a line to your .Renviron file: STRATEGUS_KEYRING_PASSWORD='<secret>' (get the real <secret> from someone)
        - Restart your R Session")
}
Strategus:::unlockKeyring(keyringName = config$keyringName)


# TODO: Add mechanism to build study section of for the config.yml? -------


# Get latest CDMs for config.yml ---------------------------------------
webApiUrl <- keyring::key_get("webApiUrl", keyring = config$keyringName) 
ROhdsiWebApi::authorizeWebApi(
  baseUrl = webApiUrl,
  authMethod = "windows"
)

# Get the keyring keys that represent the database connections
keyringKeys <- keyring::key_list(keyring = config$keyringName)$service
databaseKeyringKeys <- keyringKeys[startsWith(keyringKeys, prefix = config$keyringConnectionStringPrefix)]
databaseKeyringKeys <- databaseKeyringKeys[order(databaseKeyringKeys)]

# Get a list of latest CDM versions of data sources
cdmSources <- ROhdsiWebApi::getCdmSources(baseUrl = webApiUrl) %>%
  dplyr::filter(!is.na(.data$cdmDatabaseSchema) &
                  startsWith(.data$sourceKey, "cdm_")) %>%
  dplyr::mutate(baseUrl = webApiUrl,
                dbms = 'redshift',
                sourceDialect = 'redshift',
                port = 5439,
                version = .data$sourceKey %>% substr(., nchar(.) - 3, nchar(.)) %>% as.integer(),
                database = .data$sourceKey %>% substr(., 5, nchar(.) - 6)) %>%
  dplyr::group_by(.data$database) %>%
  dplyr::arrange(dplyr::desc(.data$version)) %>%
  dplyr::mutate(sequence = dplyr::row_number()) %>%
  dplyr::ungroup() %>%
  dplyr::arrange(.data$database, .data$sequence) %>%
  dplyr::filter(sequence == 1)

# Iterate over the keyring keys to get the latest CDM schema
latestCdms <- list()
for(databaseKey in databaseKeyringKeys) {
  connectionString <- keyring::key_get(databaseKey, keyring = config$keyringName)
  cdmSchemaRoot <- paste0("cdm_", tail(strsplit(connectionString, "/")[[1]], 1), "_v")
  cdmDatabaseSchema <- cdmSources[startsWith(cdmSources$cdmDatabaseSchema, cdmSchemaRoot), ]$cdmDatabaseSchema[[1]]
  configKey <- substr(databaseKey, nchar(config$keyringConnectionStringPrefix)+1, nchar(databaseKey))
  latestCdms[[configKey]] <- cdmDatabaseSchema
}

yamlFile <- "config.yml"
yamlConfig <- readLines(yamlFile)
findPatternTemplate <- "^  %s:.*$"
replacementPatternTemplate <- "  %s: %s"
for (i in seq_along(latestCdms)) {
  yamlConfig <- gsub(
    pattern = sprintf(findPatternTemplate, names(latestCdms)[i]), 
    replacement = sprintf(replacementPatternTemplate, names(latestCdms)[i], latestCdms[[i]]),
    yamlConfig
  )
}
cat(yamlConfig, sep = "\n", file = yamlFile)