# Instructions for Use

This project template is designed to help guide you through the various steps of running a study including CohortDiagnostics, PheValuator and Strategus. To get started, clone this repository into a new location using `git`:

- Rename the .Rproj file to the project name you plan to use. For this walk-through, we'll name this project "epi_example.Rproj"

# Project Setup

## Setup your Keyring

This is a one-time setup that you will need to perform on each machine where you plan to use this project template.

## Run _init.R

The `_init.R` file contains a script that will install the packages required by the project template and it will also ensure that your project configuration is using the latest CDMs available in our environment. 

## Edit the config.yml

The config.yml file contains the settings that are specific to your project. Here we will cover how to make changes to this file based on your project. There are two sections: `default:` and `cdm:` and we will edit the values below these headings. Please keep in mind that the YAML file format is sensitive to spacing so do not re-format the file (keep the spacing as-is).

Edit the `default:` section and update the following values:

```yaml
  studyName: "epi_example"
  rootFolder: "D:/epi_example"
  andromeda: !expr options(andromedaTempFolder = "D:/epi_example/andromedaTemp")
  resultsDatabaseSchema: "epi_example"
  studySpecificationFileName: "analysisSpecifications.json"
```

Update the `studyName` and `resultsDatabaseSchema` to your project name. Generally these will be set to the same value but aim to avoid special characters such as: /, :, ., ~, etc. Set the `rootFolder` to the path where you you have cloned this project template. Use this same path for the `andromeda` value - leave the `!expr options(andromedaTempFolder = ` section and only update the path portion leaving the `andromedaTemp` folder at the end of the path. You can optionally change the `studySpecificationFileName` but this is not required.

For the `cdm:` section, you can comment out any CDMs you do not plan to use for the project. You may also optionally re-order items in the list (i.e. if you'd like to put all of the commented out CDMs at the bottom of the list).



