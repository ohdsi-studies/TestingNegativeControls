Testing Negative Controls
=================

<img src="https://img.shields.io/badge/Study%20Status-Results%20Available-yellow.svg" alt="Study Status: Results Available">

- Analytics use case(s): **Population-Level Estimation**
- Study type: **Methods Research**
- Tags: **negative controls, Simulation, LEGEND, Hypertension**
- Study lead: **Erica A Voss**
- Study lead forums tag: **[[ericaVoss]](https://forums.ohdsi.org/u/ericaVoss)**
- Study start date: **May 17, 2018**
- Study end date: **August 20, 2023**
- Protocol: **None**
- Publications: **TBD**
- Results explorer: **Not Applicable**

**Abstract**  

*Background*  

Negative controls help assess potential residual biases in observational study designs. These controls involve exposure-outcome pairs where no causal link is believed to exist. Deviations from a null effect hint at residual systematic error. The Common Evidence Model (CEM) developed by the Observational Health Data Sciences and Informatics (OHDSI) Community facilitates the identification of negative controls. However, concerns arise when the null-assumption is breached during selection. <br>

*Methods*  

This study probes the effect of non-null negative controls on empirical calibration through a simulation and a replication study. The analysis involved assessing the impact of these negative controls on the empirical calibration process, examining how robust the calibration remains in the presence of errors. <br>

*Results*  

Empirical calibration remains robust against a few errors in negative control selection and renders results more conservative. Despite some negative controls breaching the null assumption, the empirical calibration process tolerated these deviations as long as the controls did not have strong associations. <br>

*Conclusions*  

While empirical calibration can handle some negative controls that breach the null assumption, it is crucial to avoid controls with strong associations. CEM can aid in filtering inappropriate drug-outcome pairs. Thus, the potential to generate negative control lists that contain pairs that violate the null assumption should not be a driver to change the recommendation that observational studies always include negative controls to derive an empirical null distribution used to compute calibrated p-values.

<!--
An OHDSI study repository is expected to have a README.md file where the header conforms to a standard. A template README file is provided here:

**[README file template](templateREADME.md)**

When initiating a repository, please copy this file, rename it to 'README.md', and fill in the fields as appropriate.

The information in the repository README file will be used to automatically update the [list of OHDSI research studies](https://data.ohdsi.org/OhdsiStudies/), so it is important to fill in the template accurately, and keep it up-to-date.

## Elements in the README template

| Element | Description |
| ------- | ----------- |
| [Study title]      | A meaningful title of the research project.
| Study status badge | A badge indicating the study status. See [below](#study-status) for valid options. |
| Analytics use case | One or more analytics use cases included in the study (in a comma-separated list). See [below](#analytics-use-cases) for valid options. |
| Study type | The type of study. See [below](#study-types) for valid options. |
| Tags | Zero, one, or more additional keywords that can be used to filter the list of studies. The list of tags is not restricted, but be conservative in making up new tags. For example: `EHDEN` to identify studies that are part of the [EHDEN project](https://www.ehden.eu/). |
| Study lead | The name of the study lead.|
| Study lead forums tag | The OHDSI forums tag of the study lead, which can be used to contact the lead. It is recommended to make this a hyperlink to lead's forums profile |
| Study start date | When did work on the study commence? This date typically indicates when development of the protocol was initiated. Format: [Month] [Day], [Year] (e.g. May 1, 2019)|
| Study end date | When was the study completed? This typically indicates when the analyses were completed and the results have been collected. Do not enter future (planned) dates here. Format: [Month] [Day], [Year] (e.g. May 1, 2019)|
| Protocol | A hyperlink to the protocol. The protocol is expected to be a document in the study repository itself. |
| Publications | Zero, one or more hyperlinks to papers produced as part of the study (comma-separated). |
| Results explorer | A hyperlink to a web app (e.g. a Shiny app) where the results of the study can be explored. |

### Study Status

Choose one of the following options:

| Badge             | Description                          |
| ----------------- | ------------------------------------ |
| <img src="https://img.shields.io/badge/Study%20Status-Repo%20Created-lightgray.svg" alt="Study Status: Repo Created"> | The study repository has just been created. Work has not yet commenced. |
| <img src="https://img.shields.io/badge/Study%20Status-Started-blue.svg" alt="Study Status: Started"> | A first commit was made (to something else than the README file). Work has commenced. |
| <img src="https://img.shields.io/badge/Study%20Status-Design%20Finalized-brightgreen.svg" alt="Study Status: Design Finalized"> | The protocol and study code have been finalized. |
| <img src="https://img.shields.io/badge/Study%20Status-Results%20Available-yellow.svg" alt="Study Status: Results Available"> | The study results are publicly available, for example in a paper or results explorer app. |
| <img src="https://img.shields.io/badge/Study%20Status-Complete-orange.svg" alt="Study Status: Complete"> | The study is complete, no further dissemination planned. |
| <img src="https://img.shields.io/badge/Study%20Status-Suspended-red.svg" alt="Study Status: Suspended"> | The study has been suspended, and may or may not be continued at a later point in time. |

Copy the relevant markdown code from [this page](badgesMarkdownCode.md), and paste it in your README file, just below the study title.

### Analytics Use Cases

Choose one or more options from:

- `Characterization`
- `Population-Level Estimation`, or
- `Patient-Level Prediction`

See [the Data Analytics Use Cases chapter](https://ohdsi.github.io/TheBookOfOhdsi/DataAnalyticsUseCases.html) for more details.

### Study types

Can be either:

- `Methods Research` if the study explores a methodological question, for example an evaluation of various propensity score approaches.
- `Clinical Application` if the study aims to answer a clinically relevant question, for example 'Does drug A cause outcome B?'.
-->
