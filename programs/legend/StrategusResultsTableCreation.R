# Code for creating the result schema and tables in a (Postgres) database
library(dplyr)
source("LoadConfiguration.R")

# Setup logging ----------------------------------------------------------------
ParallelLogger::addDefaultFileLogger(
  fileName = file.path(config$rootFolder, "results-schema-setup-log.txt"),
  name = "RESULTS_SCHEMA_SETUP_FILE_LOGGER"
)
ParallelLogger::addDefaultErrorReportLogger(
  fileName = file.path(config$rootFolder, 'results-schema-setup-errorReport.R'),
  name = "RESULTS_SCHEMA_SETUP_ERROR_LOGGER"
)

# Connect to the database ------------------------------------------------------
resultsDatabaseConnectionDetails <- DatabaseConnector::createConnectionDetails(
)
connection <- DatabaseConnector::connect(connectionDetails = resultsDatabaseConnectionDetails)
config$resultsDatabaseSchema = 'main'

# Create the schema ------------------------------------------------------------
#sql <- "DROP SCHEMA IF EXISTS @schema CASCADE; CREATE SCHEMA @schema;"
#sql <- SqlRender::render(sql = sql, schema = config$resultsDatabaseSchema)
#DatabaseConnector::executeSql(connection = connection, sql = sql)

# Create the tables ------------------------
if (length(databases) <= 0) {
  stop("No databases found for upload; there must be at least 1 database specified in Databases.R")
}
database <- databases[[1]]
moduleFolders <- list.dirs(path = database$strategusResultsFolder, recursive = FALSE)
isModuleComplete <- function(moduleFolder) {
  doneFileFound <- (length(list.files(path = moduleFolder, pattern = "done")) > 0)
  isDatabaseMetaDataFolder <- basename(moduleFolder) == "DatabaseMetaData"
  return(doneFileFound || isDatabaseMetaDataFolder)
}
message("Creating result tables based on definitions found in ", database$strategusResultsFolder)
for (moduleFolder in moduleFolders) {
  moduleName <- basename(moduleFolder)
  if (!isModuleComplete(moduleFolder)) {
    warning("Module ", moduleName, " did not complete. Skipping table creation")
  } else {
    if (startsWith(moduleName, "PatientLevelPrediction")) {
      message("- Creating PatientLevelPrediction tables")
      dbSchemaSettings <- PatientLevelPrediction::createDatabaseSchemaSettings(
        resultSchema = config$resultsDatabaseSchema,
        tablePrefix = "plp",
        targetDialect = DatabaseConnector::dbms(connection)
      )
      PatientLevelPrediction::createPlpResultTables(
        connectionDetails = resultsDatabaseConnectionDetails,
        targetDialect = dbSchemaSettings$targetDialect,
        resultSchema = dbSchemaSettings$resultSchema,
        deleteTables = FALSE,
        createTables = TRUE,
        tablePrefix = dbSchemaSettings$tablePrefix
      )
    } else if (startsWith(moduleName, "CohortDiagnostics")) {
      message("- Creating CohortDiagnostics tables")
      CohortDiagnostics::createResultsDataModel(
        connectionDetails = resultsDatabaseConnectionDetails,
        databaseSchema = config$resultsDatabaseSchema,
        tablePrefix = "cd_"
      )
    } else {
      message("- Creating results for module ", moduleName)
      rdmsFile <- file.path(moduleFolder, "resultsDataModelSpecification.csv")
      if (!file.exists(rdmsFile)) {
        stop("resultsDataModelSpecification.csv not found in ", resumoduleFolderltsFolder)
      } else {
        specification <- CohortGenerator::readCsv(file = rdmsFile)
        sql <- ResultModelManager::generateSqlSchema(csvFilepath = rdmsFile)
        sql <- SqlRender::render(
          sql = sql,
          database_schema = config$resultsDatabaseSchema
        )
        DatabaseConnector::executeSql(connection = connection, sql = sql)
      }
    }
  }
}

# Grant read only permissions to all tables ------------------------------------
# sql <- "GRANT USAGE ON SCHEMA @schema TO @results_user;
#         GRANT SELECT ON ALL TABLES IN SCHEMA @schema TO @results_user; 
#         GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA @schema TO @results_user;"
# sql <- SqlRender::render(
#   sql = sql, 
#   schema = config$resultsDatabaseSchema,
#   results_user = keyring::key_get("resultsUser", keyring = config$keyringName)
# )
# DatabaseConnector::executeSql(connection = connection, sql = sql)

# Disconnect from the database -------------------------------------------------
DatabaseConnector::disconnect(connection)

# Unregister loggers -----------------------------------------------------------
ParallelLogger::unregisterLogger("RESULTS_SCHEMA_SETUP_FILE_LOGGER")
ParallelLogger::unregisterLogger("RESULTS_SCHEMA_SETUP_ERROR_LOGGER")
