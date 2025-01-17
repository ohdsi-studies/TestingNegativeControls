###############################################################################
# VARIABLES
################################################################################
library(EmpiricalCalibration)

inputOutcomeOfInterests <-  read.csv("inst/settings/inputOutcomeOfInterest.csv") #contains both the true effect size and random error
inputSystematicErrors <- read.csv("inst/settings/inputSystematicError.csv")
inputNegativeControls <- read.csv("inst/settings/inputNegativeControls.csv")
inputNonNullNegativeControlsEffectSizes <- read.csv("inst/settings/inputNonNullNegativeControlsEffectSizes.csv")

outputFolder <- "results"

################################################################################
# FUNCTION
###############################################################################

fun <- function(a, inputOutcomeOfInterests, inputSystematicErrors, inputNegativeControls, inputNonNullNegativeControlsEffectSizes, outputFolder){

  doWork <- function(myRows,
                     inputOutcomeOfInterestRr, inputOutcomeOfInterestLogRr, inputOutcomeOfInterestSeLogRr,
                     inputSystematicErrorMean, inputSystematicErrorSd,
                     inputNullNegativeControls, inputNonNullNegativeControls,
                     inputNonNullNegativeControlEffectSize,
                     dataNegativeControls){

    #fit null
    null <- EmpiricalCalibration::fitMcmcNull(logRr = dataNegativeControls$logRr, seLogRr = dataNegativeControls$seLogRr)
    nullMean <- null[1]
    nullSd <- 1/sqrt(null[2])
    ease <- EmpiricalCalibration::computeExpectedAbsoluteSystematicError(null, alpha = 0.05)
    model <- EmpiricalCalibration::convertNullToErrorModel(null)

    #simulate outcome
    outcome <- EmpiricalCalibration::simulateControls(n = 1, mean = inputSystematicErrorMean, sd = inputSystematicErrorSd, seLogRr = inputOutcomeOfInterestSeLogRr, trueLogRr = inputOutcomeOfInterestLogRr)
    uncalibratedLogRr <- outcome$logRr
    uncalibratedseLogRr <- outcome$seLogRr
    uncalibratedLbLogRr <- outcome$logRr - 1.96 * outcome$seLogRr
    uncalibratedUbLogRr <- outcome$logRr + 1.96 * outcome$seLogRr
    uncalibratedPValue <- 2*pnorm(abs(outcome$logRr/outcome$seLogRr), 0,1,lower.tail = FALSE)
    uncalibratedCiContainsInputLogRR <- if(inputOutcomeOfInterestLogRr >= uncalibratedLbLogRr && inputOutcomeOfInterestLogRr <= uncalibratedUbLogRr){1} else {0}

    #calibrate
    calibratedCi <- EmpiricalCalibration::calibrateConfidenceInterval(logRr = outcome$logRr, seLogRr = outcome$seLogRr, model = model)
    calibratedLogRr <- calibratedCi$logRr
    calibratedseLogRr <- calibratedCi$seLogRr
    calibratedLbLogRr <- calibratedCi$logLb95Rr
    calibratedUbLogRr <- calibratedCi$logUb95Rr
    calibratedPValue <- EmpiricalCalibration::calibrateP(null = null,logRr = outcome$logRr, seLogRr = outcome$seLogRr)
    calibratedCiContainsInputLogRR <- if(inputOutcomeOfInterestLogRr >= calibratedLbLogRr && inputOutcomeOfInterestLogRr <= calibratedUbLogRr){1} else {0}

    #write out to CSV
    newRow <- data.frame(num = a,
                         inputOutcomeOfInterestRr,
                         inputOutcomeOfInterestLogRr,
                         inputOutcomeOfInterestSeLogRr,
                         inputSystematicErrorMean,
                         inputSystematicErrorSd,
                         inputNonNullNegativeControls,
                         inputNullNegativeControls,
                         inputNonNullNegativeControlEffectSize,
                         uncalibratedLogRr,
                         uncalibratedseLogRr,
                         uncalibratedLbLogRr,
                         uncalibratedUbLogRr,
                         uncalibratedPValue,
                         uncalibratedCiContainsInputLogRR,
                         calibratedLogRr,
                         calibratedseLogRr,
                         calibratedLbLogRr,
                         calibratedUbLogRr,
                         calibratedPValue,
                         calibratedCiContainsInputLogRR,
                         nullMean,
                         nullSd,
                         ease)

    myRows[[length(myRows) + 1]] <- newRow

    return(myRows)
  }

  set.seed(a)

  myRows <- list()

  for(b in 1:nrow(inputOutcomeOfInterests)){
    #focus on one outcome Of Interest
    inputOutcomeOfInterest <- inputOutcomeOfInterests[b,]
    inputOutcomeOfInterestRr <- inputOutcomeOfInterest$rr
    inputOutcomeOfInterestLogRr <- log(inputOutcomeOfInterest$rr)
    inputOutcomeOfInterestSeLogRr <- inputOutcomeOfInterest$seLogRr

    for(z in 1:nrow(inputSystematicErrors)){
      #focus on one systematic error setting
      inputSystematicErrorMean <- as.numeric(inputSystematicErrors[z,"errorMean"])
      inputSystematicErrorSd <- as.numeric(inputSystematicErrors[z,"errorSd"])

      for(y in 1:nrow(inputNegativeControls)){
        #focus on a certain amount of non-null negative controls
        inputNullNegativeControls <- as.numeric(inputNegativeControls[y,1])
        inputNonNullNegativeControls <- as.numeric(inputNegativeControls[y,2])

        if(inputNonNullNegativeControls == 0){ #when all negative controls are good
          #when all controls are null
          inputNonNullNegativeControlEffectSize <- 0

          #build neg list
          dataNullNegativeControls <- EmpiricalCalibration::simulateControls(n = inputNullNegativeControls, mean = inputSystematicErrorMean, sd = inputSystematicErrorSd, seLogRr = runif(inputNullNegativeControls, min = 0.01, max=0.5), trueLogRr = 0)
          #dataNonNullNegativeControls - there are 0
          dataNegativeControls <- dataNullNegativeControls

          myRows <- doWork(myRows,
                           inputOutcomeOfInterestRr, inputOutcomeOfInterestLogRr, inputOutcomeOfInterestSeLogRr,
                           inputSystematicErrorMean, inputSystematicErrorSd,
                           inputNullNegativeControls, inputNonNullNegativeControls,
                           inputNonNullNegativeControlEffectSize,
                           dataNegativeControls)
          }
        else {  #when some negative controls are imperfect

          for(x in 1:nrow(inputNonNullNegativeControlsEffectSizes)){
            #select effect size for non-null negative control
            inputNonNullNegativeControlEffectSize <- as.numeric(inputNonNullNegativeControlsEffectSizes[x,"rr"])

            #build neg list
            dataNullNegativeControls <- EmpiricalCalibration::simulateControls(n = inputNullNegativeControls, mean = inputSystematicErrorMean, sd = inputSystematicErrorSd, seLogRr = runif(inputNullNegativeControls, min = 0.01, max=0.5), trueLogRr = 0)
            dataNonNullNegativeControls <- EmpiricalCalibration::simulateControls(n = inputNonNullNegativeControls, mean = inputSystematicErrorMean, sd = inputSystematicErrorSd, seLogRr = runif(inputNonNullNegativeControls, min = 0.01, max=0.5), trueLogRr = log(inputNonNullNegativeControlEffectSize))
            dataNegativeControls <- rbind(dataNullNegativeControls,dataNonNullNegativeControls)

            myRows <- doWork(myRows,
                             inputOutcomeOfInterestRr, inputOutcomeOfInterestLogRr, inputOutcomeOfInterestSeLogRr,
                             inputSystematicErrorMean, inputSystematicErrorSd,
                             inputNullNegativeControls, inputNonNullNegativeControls,
                             inputNonNullNegativeControlEffectSize,
                             dataNegativeControls)
          }
        }
      }
    }
  }

  myRows <- dplyr::bind_rows(myRows)
  saveRDS(myRows, file=paste0(outputFolder,"/myRows_",a,".rds"))
  return(myRows)
}

################################################################################
# RUN
################################################################################

#Cluster Run
cluster <- ParallelLogger::makeCluster(numberOfThreads = 1)
results <- ParallelLogger::clusterApply(cluster, 1001:1001,
                                        fun,
                                        inputOutcomeOfInterests,
                                        inputSystematicErrors,
                                        inputNegativeControls,
                                        inputNonNullNegativeControlsEffectSizes,
                                        outputFolder)
ParallelLogger::stopCluster(cluster)

results <- dplyr::bind_rows(results)

write.csv(results,paste0(outputFolder,"/simulation_scenarios.csv"))

################################################################################
# TESTING
################################################################################

# #simple run to test function
# inputOutcomeOfInterest <-  read.csv("inst/settings/inputOutcomeOfInterest.csv") #contains both the true effect size and random error
# inputSystematicError <- read.csv("inst/settings/inputSystematicError.csv")
# inputNegativeControls <- read.csv("inst/settings/inputNegativeControls.csv")
# inputNonNullNegativeControlsEffectSizes <- read.csv("inst/settings/inputNonNullNegativeControlsEffectSizes.csv")
# a <- 1
# inputOutcomeOfInterest <- inputOutcomeOfInterest #20
# inputSystematicError <- inputSystematicError #3
# inputNegativeControls <- inputNegativeControls #4
# inputNonNullNegativeControlsEffectSizes <- inputNonNullNegativeControlsEffectSizes
#
# fun(a, inputOutcomeOfInterests, inputSystematicErrors, inputNegativeControls, inputNonNullNegativeControlsEffectSizes, outputFolder)

