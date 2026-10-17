<h1 align="center">Layoffs Data Analysis | SQL</h1>

<p align="center">
  An exploratory data analysis project examining company layoffs between March 2020 and March 2023 using MySQL.
</p>

## Overview

Layoffs Data Analysis explores reported workforce reductions during a period of significant changes in the global economy and technology industry. Using SQL, I cleaned the raw dataset and performed exploratory analysis to understand how recorded layoffs varied across different categories and over time.

The project covers the complete workflow from preparing a usable dataset to aggregating results, identifying trends, and ranking companies by reported layoffs.

## Objectives

- Clean and standardize the raw dataset for analysis.
- Identify and remove duplicate records.
- Handle missing values without making unsupported assumptions.
- Analyze reported layoffs across companies, industries, countries, and company stages.
- Examine yearly and monthly trends using aggregations and window functions.
- Rank companies by total recorded layoffs within each year.

## Tech Stack

- **Database:** MySQL
- **Language:** SQL
- **Techniques:** Data Cleaning, Exploratory Data Analysis, Aggregations, Common Table Expressions (CTEs), Window Functions, `ROW_NUMBER()`, `DENSE_RANK()`, Rolling Totals

## Dataset

The dataset contains company layoff records spanning March 11, 2020, to March 6, 2023.

The analysis uses the following fields, among others:

- Company, industry, and location
- Total employees laid off
- Percentage of workforce laid off
- Date, company stage, and country
- Funds raised in millions

The cleaned working dataset contains **1,995 records**. One record has a missing date, so time-based analyses use the 1,994 records with valid dates.

## Data Cleaning

The raw data was preserved while cleaning was performed on staging tables. The cleaning process included:

- Identifying duplicate records using `ROW_NUMBER()` and removing duplicate entries.
- Trimming company names and standardizing inconsistent industry and country labels.
- Converting date strings into SQL `DATE` values.
- Converting blank industry and percentage values to `NULL`.
- Filling missing industry labels when another record for the same company provided a known value.
- Removing records where both total layoffs and layoff percentage were unavailable.
- Validating percentage values and converting percentage and funding columns to numeric data types.

After cleaning, the duplicate validation query returned no duplicate groups. Some missing values remain where information was unavailable, rather than being filled with assumptions.

## Exploratory Data Analysis

The analysis explores:

- **Company-level layoffs:** Total recorded layoffs by company.
- **Industry and country breakdowns:** Comparing reported layoffs across industries and countries.
- **Company stage:** Examining layoffs by funding or business stage.
- **Yearly trends:** Comparing total recorded layoffs across calendar years.
- **Monthly trends:** Identifying months with unusually high recorded layoffs.
- **Rolling totals:** Calculating cumulative layoffs over time using window functions.
- **Yearly company rankings:** Using CTEs and `DENSE_RANK()` to identify the five highest-layoff companies in each year.
- **Complete-layoff records:** Examining companies reporting layoffs equivalent to 100% of their workforce.

## Key Findings

The analysis produced the following results:

- **383,159 recorded layoffs** across records with valid dates.
- **2022 had the highest annual total**, with 160,661 recorded layoffs.
- **January 2023 had the highest monthly total**, with 84,714 recorded layoffs.
- **The United States ranked first** by country, with 256,559 recorded layoffs, followed by India with 35,993.
- **Amazon had the highest company-level total**, with 18,150 recorded layoffs, followed by Google with 12,000 and Meta with 11,000.
- The maximum number of layoffs recorded in a single row was 12,000.

## Limitations

- The dataset represents reported layoffs and may not capture every workforce reduction that occurred.
- Missing layoff figures can affect totals for individual companies and categories.
- Records with missing dates are excluded from yearly, monthly, and rolling-total analyses.
- The dataset ends on March 6, 2023. Therefore, 2023 represents only a partial year and should not be compared directly with complete calendar years.
- The analysis describes patterns in the available data; it does not establish the causes of layoffs.

## Project Structure

```text
layoffs-data-analysis/
├── data/
│   └── layoffs.csv
├── sql/
│   ├── 01_data_cleaning.sql
│   └── 02_exploratory_data_analysis.sql
├── .gitignore
└── README.md
```




