# Code for setting the connection details and schemas for the various databases,
# as well as some folders in the local file system.

# Get the study configuration from the config.yml ----------
config <- config::get(config = "studySettings")

# Ensure the keyring is unlocked -------------
Strategus:::unlockKeyring(keyringName = config$keyringName)

# Build the databases list --------------------
cdmSources <- names(config$cdm)[!names(config$cdm) %in% names(config)]
databases <- list()
for (i in seq_along(cdmSources)) {
  databases[[length(databases) + 1]] <- list(
    databaseId = cdmSources[i],
    connectionDetails = DatabaseConnector::createConnectionDetails(
      dbms = "redshift",
      connectionString = keyring::key_get(paste0(config$keyringConnectionStringPrefix, databaseId), keyring = config$keyringName),
      user = keyring::key_get("redShiftUserName", keyring = config$keyringName),
      password = keyring::key_get("redShiftPassword", keyring = config$keyringName)
    ),
    cohortDatabaseSchema = keyring::key_get("redShiftScratchSchema", keyring = config$keyringName),
    cdmDatabaseSchema = config$cdm[[cdmSources[i]]]
  )
}

# Set cohort table and folders -------------------------------------------------
for (i in seq_along(databases)) {
  databaseId <- databases[[i]]$databaseId
  databases[[i]]$cohortTable <- sprintf("cohort_%s_%s", config$studyName, databaseId)
  databases[[i]]$databaseResultsRootFolder <- file.path(config$rootFolder, "results", databaseId)
  databases[[i]]$cohortDiagnosticsFolder = file.path(databases[[i]]$databaseResultsRootFolder, "cohortDiagnostics")
  databases[[i]]$pheValuatorFolder = file.path(databases[[i]]$databaseResultsRootFolder, ("pheValuator"))
  databases[[i]]$strategusResultsFolder = file.path(databases[[i]]$databaseResultsRootFolder, ("strategusResults"))
  # Set the Strategus internals folders - these will be explicitly ignored by git so that they are not
  # automatically included in the study repo due to size considerations
  databases[[i]]$strategusInternalsRootFolder <- file.path(config$rootFolder, "strategusInternals", databaseId)
  databases[[i]]$strategusWorkFolder <- file.path(databases[[i]]$strategusInternalsRootFolder, ("strategusWork"))
  databases[[i]]$strategusExecutionFolder = file.path(databases[[i]]$strategusInternalsRootFolder, ("strategusExecution"))
}

# Results database -------------------------------------------------------------
# resultsDatabaseConnectionDetails <- DatabaseConnector::createConnectionDetails(
#   dbms = "postgresql",
#   connectionString = keyring::key_get("resultsServer", keyring = config$keyringName),
#   user = keyring::key_get("resultsUser", keyring = config$keyringName),
#   password = keyring::key_get("resultsPassword", keyring = config$keyringName),
# )
resultsDatabaseConnectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = "sqlite",server = "D:\\programs\\legend\\results\\results.sqlite"
)
