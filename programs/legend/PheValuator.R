# Code for running PheValuator, including generating the xSpec and xSens cohorts
# Assumes the cohort set has been downloaded and generated on the databases 
# (i.e., that Cohorts.R has been executed).
source("LoadConfiguration.R")

# Create PheValuator settings --------------------------------------------------
cohortDefinitionSet <- CohortGenerator::getCohortDefinitionSet(
  settingsFileName = file.path(config$rootFolder, "cohorts/inst/Cohorts.csv"),
  jsonFolder = file.path(config$rootFolder, "cohorts/inst/cohorts"),
  sqlFolder = file.path(config$rootFolder, "cohorts/inst/sql/sql_server"),
  subsetJsonFolder = file.path(config$rootFolder, "cohorts/inst/cohort_subset_definitions")  
)

covariateSettings <- PheValuator::createDefaultCovariateSettings(
  excludedCovariateConceptIds = config$pheValuator$excludedCovariateConceptIds,
  addDescendantsToExclude = TRUE,
  startDayWindow1 = 0,
  endDayWindow1 = 10,
  startDayWindow2 = 11,
  endDayWindow2 = 20,
  startDayWindow3 = 21,
  endDayWindow3 = 30
)
createEvaluationCohortArgs <- PheValuator::createCreateEvaluationCohortArgs(
  xSpecCohortId = config$pheValuator$xSpecCohortId,
  daysFromxSpec = 1,
  xSensCohortId = config$pheValuator$xSensCohortId,
  prevalenceCohortId = config$pheValuator$prevalenceCohortId
)
analysisList <- list()
for (i in seq_along(config$pheValuator$toEvaluateCohortIds)) {
  testPhenotypeAlgorithmArgs <- PheValuator::createTestPhenotypeAlgorithmArgs(
    phenotypeCohortId = config$pheValuator$toEvaluateCohortIds[i],
    splayPrior = 30,
    splayPost = 7
  )
  analysisList[[i]] <- PheValuator::createPheValuatorAnalysis(
    analysisId = i,
    description = cohortDefinitionSet$cohortName[cohortDefinitionSet$cohortId == config$pheValuator$toEvaluateCohortIds[i]],
    createEvaluationCohortArgs = createEvaluationCohortArgs,
    testPhenotypeAlgorithmArgs = testPhenotypeAlgorithmArgs
  )
}
PheValuator::savePheValuatorAnalysisList(analysisList, file.path(config$rootFolder, config$pheValuator$analysisListFileName))

# Run PheValuator --------------------------------------------------------------
analysisList <- PheValuator::loadPheValuatorAnalysisList(file.path(config$rootFolder, config$pheValuator$analysisListFileName))
for (i in seq_along(databases)) {
  database <- databases[[i]]
  message(sprintf("running PheValuator for %s", database$databaseId))
  PheValuator::runPheValuatorAnalyses(
    connectionDetails = database$connectionDetails,
    cdmDatabaseSchema = database$cdmDatabaseSchema,
    cohortDatabaseSchema = database$cohortDatabaseSchema,
    cohortTable = database$cohortTable,
    workDatabaseSchema = database$cohortDatabaseSchema,
    outputFolder = database$pheValuatorFolder,
    pheValuatorAnalysisList = analysisList
  )
  results <- PheValuator::summarizePheValuatorAnalyses(
    referenceTable = readRDS(file.path(database$pheValuatorFolder, "reference.rds")),
    outputFolder = database$pheValuatorFolder
  )
  readr::write_csv(results, file.path(database$pheValuatorFolder, "summary.csv"))
}