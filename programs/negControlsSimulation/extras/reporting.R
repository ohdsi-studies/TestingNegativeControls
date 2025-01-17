outputFolder <- "results"

# Load required packages
library(purrr)
library(dplyr)

# Set your working directory
setwd(outputFolder)

# Get a list of all RDS files in the folder
rds_files <- list.files(pattern = "\\.rds$")

# Read and combine RDS files
combined_data <- map(rds_files, readRDS) %>%
  bind_rows()

# Output combined data to a CSV file
write.csv(combined_data, "simulation_scenarios.csv", row.names = FALSE)

# Optionally, you can also use write_csv() from the readr package for more control over CSV output
# install.packages("readr")
# library(readr)
# write_csv(combined_data, "combined_data.csv")

df <- read.csv(paste0("simulation_scenarios.csv"))
df$uncalibratedPrecision <- 1/(df$uncalibratedseLogRr^2)
df$calibratedPrecision <- 1/(df$calibratedseLogRr^2)

universe <- sqldf::sqldf("SELECT DISTINCT
                           inputOutcomeOfInterestRr,
                           inputOutcomeOfInterestSeLogRr,
                           inputSystematicErrorMean,
                           inputSystematicErrorSd,
                           inputNonNullNegativeControls,
                           inputNullNegativeControls,
                           inputNonNullNegativeControlEffectSize,
                           AVG(uncalibratedCiContainsInputLogRR) AS AVG_uncalibratedCiContainsInputLogRR,
                           AVG(uncalibratedseLogRr) AS AVG_uncalibratedseLogRr,
                           AVG(uncalibratedLogRr) AS AVG_uncalibratedLogRr,
                           AVG(uncalibratedLbLogRr) AS AVG_uncalibratedLbLogRr,
                           AVG(uncalibratedUbLogRr) AS AVG_uncalibratedUbLogRr,
                           EXP(AVG(LOG(uncalibratedPrecision))) AS GEOMEAN_uncalibratedPrecision,
                           AVG(calibratedCiContainsInputLogRR) AS AVG_calibratedCiContainsInputLogRR,
                           AVG(calibratedseLogRr) AS AVG_calibratedseLogRr,
                           AVG(calibratedLogRr) AS AVG_calibratedLogRr,
                           AVG(calibratedLbLogRr) AS AVG_calibratedLbLogRr,
                           AVG(calibratedUbLogRr) AS AVG_calibratedUbLogRr,
                           EXP(AVG(LOG(calibratedPrecision))) AS GEOMEAN_calibratedPrecision,
                           AVG(nullMean) AS AVG_nullMean,
                           AVG(nullSd) AS AVG_nullSd
                         FROM df
                         WHERE inputOutcomeOfInterestSeLogRr != 0.01
                         GROUP BY inputOutcomeOfInterestRr,
                           inputOutcomeOfInterestSeLogRr,
                           inputSystematicErrorMean,
                           inputSystematicErrorSd,
                           inputNonNullNegativeControls,
                           inputNullNegativeControls,
                           inputNonNullNegativeControlEffectSize")

write.csv(universe,paste0("simulation_scenarios_summarized.csv"))

universeGoodModel <- sqldf::sqldf("SELECT *
                                  FROM universe
                                  WHERE inputSystematicErrorMean = 0
                                  AND inputSystematicErrorSd = 0")

universeOkayModel <- sqldf::sqldf("SELECT *
                                  FROM universe
                                  WHERE inputSystematicErrorMean = 0
                                  AND inputSystematicErrorSd = 0.2")

universeBadModel <- sqldf::sqldf("SELECT *
                                  FROM universe
                                  WHERE inputSystematicErrorMean = 0.2
                                  AND inputSystematicErrorSd = 0.2")

universePivot <- sqldf::sqldf("SELECT g.inputOutcomeofInterestRr,
                                g.inputOutcomeOfInterestSeLogRr,
                                g.inputNonNullNegativeControls,
                                g.inputNonnullNegativeControlEffectSize,

                                g.AVG_uncalibratedCiContainsInputLogRR AS GOOD_AVG_uncalibratedCiContainsInputLogRR,
                                g.GEOMEAN_uncalibratedPrecision AS GOOD_GEOMEAN_uncalibratedPrecision,
                                g.AVG_calibratedCiContainsInputLogRR AS GOOD_AVG_calibratedCiContainsInputLogRR,
                                g.GEOMEAN_calibratedPrecision AS GOOD_GEOMEAN_calibratedPrecision,

                                o.AVG_uncalibratedCiContainsInputLogRR AS OKAY_AVG_uncalibratedCiContainsInputLogRR,
                                o.GEOMEAN_uncalibratedPrecision AS OKAY_GEOMEAN_uncalibratedPrecision,
                                o.AVG_calibratedCiContainsInputLogRR AS OKAY_AVG_calibratedCiContainsInputLogRR,
                                o.GEOMEAN_calibratedPrecision AS OKAY_GEOMEAN_calibratedPrecision,

                                b.AVG_uncalibratedCiContainsInputLogRR AS OKAY_AVG_uncalibratedCiContainsInputLogRR,
                                b.GEOMEAN_uncalibratedPrecision AS OKAY_GEOMEAN_uncalibratedPrecision,
                                b.AVG_calibratedCiContainsInputLogRR AS OKAY_AVG_calibratedCiContainsInputLogRR,
                                b.GEOMEAN_calibratedPrecision AS OKAY_GEOMEAN_calibratedPrecision
                              FROM universeGoodModel g
                                JOIN universeOkayModel o
                                  ON o.inputOutcomeofInterestRr = g.inputOutcomeOfInterestRr
                                  AND o.inputOutcomeOfInterestSeLogRr = g.inputOutcomeOfInterestSeLogRr
                                  AND o.inputNonNullNegativeControls = g.inputNonNullNegativeControls
                                  AND o.inputNonNullNegativeControlEffectSize = g.inputNonnullNegativeControlEffectSize
                                JOIN universeBadModel b
                                  ON b.inputOutcomeofInterestRr = g.inputOutcomeOfInterestRr
                                  AND b.inputOutcomeOfInterestSeLogRr = g.inputOutcomeOfInterestSeLogRr
                                  AND b.inputNonNullNegativeControls = g.inputNonNullNegativeControls
                                  AND b.inputNonNullNegativeControlEffectSize = g.inputNonnullNegativeControlEffectSize")

write.csv(universePivot, "simulation_scenarios_summarized_pivot.csv")





# Install and load the ggplot2 package
library(ggplot2)
library(dplyr)

#Updated Results
drugOfInterestLogRR <- data.frame(unique(df$drugofInterestLogRR))
names(drugOfInterestLogRR) <- c("drugsOfInterestLogRR")

drugOfInterestseLogRR <- data.frame(unique(df$drugofInterestseLogRR ))
names(drugOfInterestseLogRR) <- c("drugsOfInterestseLogRR")

imperfectNegativeControls <- data.frame(unique(df$imperfectNegativeControls))
names(imperfectNegativeControls) <- c("imperfectNegativeControls")

negativeControlEffectSize <- data.frame(unique(df$negativeControlEffectSize))
names(negativeControlEffectSize) <- c("negativeControlEffectSize")

df$systematicErrorMeanSd <- paste0(df$systematicErrorMean,"-",df$systematicErrorSD)
systematicErrorMeanSd <- data.frame(unique(df$systematicErrorMeanSd))
names(systematicErrorMeanSd) <- c("systematicErrorMeanSd")

trueNegatives <- data.frame(unique(df$trueNegative))
names(trueNegatives) <- c('trueNegative')

truePositives <- data.frame(unique(df$truePositive))
names(truePositives) <- c('truePositive')

falseNegatives <- data.frame(unique(df$falseNegative))
names(falseNegatives) <- c('falseNegative')

falsePositives <- data.frame(unique(df$falsePositive))
names(falsePositives) <- c('falsePositive')

universe <- sqldf::sqldf("SELECT DISTINCT *, NULL AS count, NULL as pct, NULL AS denominator
                         FROM drugOfInterestLogRR, drugOfInterestseLogRR,
                          imperfectNegativeControls, negativeControlEffectSize,
                          systematicErrorMeanSd, trueNegatives, truePositives, falseNegatives, falsePositives
                         WHERE (
                          (imperfectNegativeControls IN (0) AND negativeControlEffectSize IN (0))
                          OR (imperfectNegativeControls IN (1,3,9) AND negativeControlEffectSize IN (1.5,2.0,4.0))
                         )
                         AND trueNegative + truePositive + falseNegative + falsePositive = 1")

#count people
for(z in 1:nrow(universe)){
  row <- universe[z,]
  roundToTest <- df[df$drugofInterestLogRR == row$drugsOfInterestLogRR &
                      df$drugofInterestseLogRR == row$drugsOfInterestseLogRR &
                      df$imperfectNegativeControls == row$imperfectNegativeControls &
                      df$negativeControlEffectSize == row$negativeControlEffectSize &
                      df$systematicErrorMeanSd == row$systematicErrorMeanSd &
                      df$trueNegative == row$trueNegative &
                      df$truePositive == row$truePositive &
                      df$falseNegative == row$falseNegative &
                      df$falsePositive == row$falsePositive, ]

  universe[z,"count"] <- nrow(roundToTest)
}

#calculate percentages
for(i in 1:nrow(universe)){
  row <- universe[i,]
  multiRows <- universe[universe$drugsOfInterestLogRR == row$drugsOfInterestLogRR &
                         universe$drugsOfInterestseLogRR == row$drugsOfInterestseLogRR &
                         universe$imperfectNegativeControls == row$imperfectNegativeControls &
                         universe$negativeControlEffectSize == row$negativeControlEffectSize &
                         universe$systematicErrorMeanSd == row$systematicErrorMeanSd, ]

  universe[i,"pct"] <- row$count *1.0 / sum(multiRows$count)
  universe[i,"denominator"] <- sum(multiRows$count)
}

library(tidyr)

# Pivot the data
pivoted_universe <- universe %>%
  pivot_wider(
    id_cols = c(
      drugsOfInterestLogRR,
      drugsOfInterestseLogRR,
      imperfectNegativeControls,
      negativeControlEffectSize,
      systematicErrorMeanSd
    ),
    names_from = c("trueNegative", "truePositive", "falseNegative", "falsePositive"),
    values_from = count,
    values_fill = 0
  )

colnames(pivoted_universe)[6] <- c("trueNegative")
colnames(pivoted_universe)[7] <- c("truePositive")
colnames(pivoted_universe)[8] <- c("falseNegative")
colnames(pivoted_universe)[9] <- c("falsePositive")

pivoted_universe$total <- pivoted_universe$trueNegative + pivoted_universe$truePositive + pivoted_universe$falseNegative + pivoted_universe$falsePositive

pivoted_universe$negativeControlEffectSizeAndCount <- paste0(pivoted_universe$negativeControlEffectSize, " ~ ", pivoted_universe$imperfectNegativeControls)

# Install and load the required packages
# Load required libraries
library(tidyr)
library(ggplot2)

# Assuming you have pivoted_universe dataframe
# Reshape the data into a long format
long_pivoted_universe <- pivot_longer(pivoted_universe,
                                      cols = c(trueNegative, truePositive, falseNegative, falsePositive),
                                      names_to = "variable",
                                      values_to = "value")

long_pivoted_universe$drugsOfInterestLogRR <- factor(long_pivoted_universe$drugsOfInterestLogRR)
long_pivoted_universe$drugsOfInterestseLogRR <- factor(long_pivoted_universe$drugsOfInterestseLogRR)


# Create the stacked bar charts for each unique value of systematicErrorMeanSd

values <- unique(long_pivoted_universe$systematicErrorMeanSd)
values_effectSize  <- unique(long_pivoted_universe$negativeControlEffectSize)

for (i in 1:length(values)) {
  df_plot <- long_pivoted_universe[long_pivoted_universe$systematicErrorMeanSd == values[i],]

    plot <- ggplot(df_plot,
                   aes(fill = variable, y = value, x = drugsOfInterestseLogRR)) +
      geom_bar(position = "stack", stat = "identity") +
      facet_grid(negativeControlEffectSizeAndCount ~ drugsOfInterestLogRR) +
      labs(title = paste("Systematic Error (mean-SD):", values[i]),
           x = "Drugs Of Interest seLog RR",
           y = "Count",
           fill = "Variable") +
      scale_y_continuous(limits = c(0, 100)) + # just for now
      geom_text(aes(label = value), vjust = 0) +
      theme_minimal() +
      theme(legend.position = "bottom")

    #print(plot)

    # Save the plot as an image file (e.g., PNG)
    ggsave(filename = paste(outputFolder,"/simulationPlot_", values[i],".png", sep = ""), plot = plot, width = 10, height = 10)

}



library(ggplot2)
library(ggh4x)


plotDf_typeITypeII <- transform(
  typeITypeII,
  type = ifelse(drugsOfInterestLogRR == 1, "Type I", "Type II")
)

#imperfectNegativeControlsAndEffectSize vs systematicErrorMeanSd

unique_controls <- unique(plotDf_typeITypeII$systematicErrorMeanSd)

# Create a list to store individual plots
plot_list <- list()

for(control_value in unique_controls){
  # Subset the dataframe for the current control value
  subset_df <- subset(plotDf_typeITypeII, systematicErrorMeanSd == control_value)

  # Create the plot for the current control value
  current_plot <- ggplot(subset_df, aes(x = as.factor(drugsOfInterestseLogRR), y = pct)) +
    geom_bar(stat = "identity", fill = "steelblue") +
    labs(title = paste("Percentage by Type - Systematic Error (mean-SD):", control_value),
         x = "Outcome of Interest Random Error",
         y = "Percentage") +
    scale_y_continuous(limits = c(0, 1.2)) + # just for now
    geom_text(aes(label = round(pct, 2)), vjust = -0.5) +
    facet_nested(imperfectNegativeControlsAndEffectSize ~ type + drugsOfInterestLogRR) +
    theme(strip.placement = "outside", strip.text = element_text(angle = 0, hjust = 0))

  # Store the plot in the list
  plot_list[[as.character(control_value)]] <- current_plot

  # Save the plot as an image file (e.g., PNG)
  ggsave(filename = paste(outputFolder,"/simulationPlot_", control_value, ".png", sep = ""), plot = current_plot, width = 10, height = 10)
}

# Print or display the individual plots
for (i in seq_along(plot_list)) {
  print(plot_list[[i]])
}

