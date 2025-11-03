# Bird Watch Visualization App

![NaarmWings Logo](Data/Logo/NaarmWings%20Logo.svg)

## [Access the Live Shiny App](https://naarm-wings.shinyapps.io/a3-geom90007/)

---

## About This Project

This is our **Assignment 3** for **Information Visualisation (GEOM90007)** at the
University of Melbourne. We built an interactive app that shows bird sightings
around Melbourne using R Shiny and Tableau.

The app lets users explore where different bird species have been spotted in
Melbourne, when they were seen, and how bird diversity varies across the city.
We used real data from BirdLife Australia to make this visualization.

## Our Team

- **Sarathi Thirumalai Soundararajan** - [sthirumalais@student.unimelb.edu.au](mailto:sthirumalais@student.unimelb.edu.au)
- **Eby Thomas** - [thomas.e2@student.unimelb.edu.au](mailto:thomas.e2@student.unimelb.edu.au)
- **Harish Kannan** - [harish.kannan@student.unimelb.edu.au](mailto:harish.kannan@student.unimelb.edu.au)
- **Mahek Jain** - [mahek.jain@student.unimelb.edu.au](mailto:mahek.jain@student.unimelb.edu.au)

---

## Data We Used

We got our bird sighting data from **BirdLife Australia's Birdata** database
through the **Atlas of Living Australia**. The dataset has over 32,000 bird
observation records within the **City of Melbourne (LGA: Melbourne)**.

We gratefully acknowledge **BirdLife Australia** and the **Atlas of Living
Australia** for making these data openly available for educational purposes.

### Data Citation

> Atlas of Living Australia occurrence download at
> [ALA occurrence search][ala-occurrence] accessed on 20 October 2025.  
> Descriptive and image content retrieved via the Wikipedia REST API accessed on
> 20 October 2025.  
> Audio content accessed via the Xeno-Canto API on 20 October 2025 for
> academic, non-commercial use.  
> Morphological trait data derived from the AVONET global bird dataset and
> merged with species occurrence records using the scientific name field
> accessed on 22 October 2025.  
> Spatial boundary and locality shapefiles obtained from the City of Melbourne
> Open Data Portal and Geoscape Administrative Boundaries accessed on 25 October
> 2025.

**DOIs:**

- Atlas of Living Australia: [Dataset DOI][ala-doi]

**Data sources:**

- **BirdLife Australia (2019).** *Birdata* ([Birdata][birdata-site]).  
  Accessed via the ALA on 01/03/2019.  
  For more information: [ALA dataset dr359][ala-dr359].

- **Records provided by BirdLife Australia**, accessed through ALA website.  
  For more information: [ALA dataset dp28][ala-dp28].

- **Wikipedia contributors (2025).** *Species descriptions and representative
  images retrieved via the Wikipedia REST API.*  
  API endpoint: [Wikipedia REST API][wikipedia-rest].  
  Documentation: [MediaWiki REST API docs][mediawiki-rest].

- **City of Melbourne (Open Data Portal).** *Municipal Boundary Dataset* (City of
  Melbourne shapefile).  
  Downloaded from [Municipal boundary export][melbourne-boundary].

- **Geoscape Australia / Commonwealth of Australia (2025).**  
  *VIC Suburb/Locality Boundaries – Geoscape Administrative Boundaries
  (GDA2020).*  
  Downloaded from [Geoscape administrative boundaries][geoscape-admin].  
  Licensed under **CC BY 4.0**.

- **Tobias, J.A., et al. (2022).** *AVONET: Morphological, ecological and
  geographical data for all birds.*  
  Downloaded from [AVONET dataset][avonet-dataset].  
  Merged with pre-processed occurrence data using the scientific name field.

- **Xeno-Canto Foundation.** *Xeno-Canto — Bird sounds from around the world*
  [Dataset].  
  Includes bird call recordings displayed with per-track attribution.  
  Global Biodiversity Information Facility (GBIF) DOI: [GBIF DOI][gbif-doi].  
  Licensed under **CC BY-NC-ND 4.0** and **CC BY-NC-SA 4.0**.  
  Terms of Use: [Xeno-Canto terms][xeno-terms].

---

## Third-Party Libraries

This project uses the **tableau-in-shiny** R library (version 1.2, 2024-09-04)
written by **Alan Thomas** from the University of Melbourne. This library is
provided as part of the GEOM90007 Information Visualisation course materials
and enables seamless embedding of Tableau Public visualizations in Shiny
applications using the Tableau Embedding API v3.

- **File**: `R/tableau-in-shiny-v1.2.R`  
- **Author**: Alan Thomas, University of Melbourne  
- **Copyright**: 2023–2024 The University of Melbourne  
- **License**: MIT License  

We gratefully acknowledge the provision of this library code for educational
purposes in the GEOM90007 course.

---

## Getting Started

> **Note:** This app uses CSS styles that are not supported by the built-in
> RStudio viewer. For the best experience, open the app in an **external
> browser**.

### Install R dependencies

```r
source("./R/libraries.R")
```

### Run the Shiny app (interactive)

From the project root directory:

```r
shiny::runApp()
```

### Run the Shiny app without launching a browser

```r
shiny::runApp(launch.browser = FALSE)
```

---

## Optional Build Steps (Webpack Assets)

Some front-end assets are compiled with webpack from `./src` to `./www`. Only run
these steps if you need to modify the non-R source files.

### Install Node.js dependencies

```bash
npm install
```

### Build assets

```bash
npm run build
```

---

## Project Structure

```text
root
├── Data: data sources for the dashboard
├── R: supporting R scripts for the app
├── src: supporting non-R source files and assets
└── www: production non-R files and assets for use by the app
```

---

## Limitations & Future Work

- Audio data is missing for eight bird species, so playback is unavailable for
  those entries.
- The AVONET morphological dataset is prepared but not yet integrated; future
  versions will incorporate it to extend the visual and analytical features.

<!-- markdownlint-disable MD013 -->
[ala-occurrence]: https://biocache.ala.org.au/occurrences/search
[ala-doi]: https://doi.org/10.26197/ala.aaf6d193-fcff-4c92-9f10-607c1fbda846
[birdata-site]: http://www.birdata.com.au
[ala-dr359]: https://collections.ala.org.au/public/show/dr359
[ala-dp28]: https://collections.ala.org.au/public/show/dp28
[wikipedia-rest]: https://en.wikipedia.org/api/rest_v1/
[mediawiki-rest]: https://www.mediawiki.org/wiki/API:REST_API
[melbourne-boundary]:
  https://data.melbourne.vic.gov.au/explore/dataset/municipal-boundary/export/
[geoscape-admin]:
  https://data.gov.au/data/dataset/vic-suburb-locality-boundaries-geoscape-administrative-boundaries/resource/14a2bec8-cb31-428c-a5eb-c298f466c46d
[avonet-dataset]: https://figshare.com/s/b990722d72a26b5bfead
[gbif-doi]: https://doi.org/10.15468/qv0ksn
[xeno-terms]: https://xeno-canto.org/about/terms
<!-- markdownlint-enable MD013 -->

---
