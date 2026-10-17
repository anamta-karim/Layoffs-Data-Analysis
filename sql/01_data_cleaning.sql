-- PROJECT: Layoffs Data Analysis (March 2020 - March 2023)
-- PURPOSE: Clean and standardize the layoffs dataset before EDA

-- ============================================================
-- 1. CREATE A STAGING TABLE
-- Preserve the original dataset and perform cleaning on a copy. 

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging 
SELECT * 
FROM layoffs;

-- Inspect the copied dataset
SELECT * FROM layoffs_staging;

-- ============================================================
-- 2. IDENTIFY DUPLICATE RECORDS
-- ROW_NUMBER() assigns a sequence to records sharing the
-- same values across all relevant columns.

WITH duplicate_cte AS (
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
) 
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

-- Inspect a specific company if needed
SELECT * 
FROM layoffs_staging
WHERE company = 'Casper';

-- ============================================================
-- 3. CREATE A SECOND STAGING TABLE
-- Store the row number so duplicate records can be deleted
-- safely from the working table.

CREATE TABLE layoffs_staging2 (
	company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT DEFAULT NULL,
    percentage_laid_off TEXT,
    `date` TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions DECIMAL(12,2) DEFAULT NULL,
    row_num INT
);

-- Copy records and assign a row number within each group of otherwise identical records.
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Remove duplicate records, retaining one record per group
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- ============================================================
-- 4. STANDARDIZE TEXT VALUES
-- Remove unwanted whitespace and normalize inconsistent labels.

-- Trim leading and trailing spaces from company names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Inspect inconsistent industry labels
SELECT DISTINCT industry
FROM layoffs_staging2
WHERE LOWER(industry) LIKE '%crypto%';

-- Standardize cryptocurrency-related industry labels
UPDATE layoffs_staging2
SET industry = 'Crypto' 
WHERE LOWER(industry) LIKE '%crypto%';

-- Inspect country names before standardization
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;

-- Remove trailing periods from United States country labels
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Verify standardized country names
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;

-- ============================================================
-- 5. STANDARDIZE DATE VALUES
-- Convert date strings into a proper SQL DATE column.
-- Source format: MM/DD/YYYY

-- Inspect existing date values
SELECT `date`
FROM layoffs_staging2;

-- Convert text dates into YYYY-MM-DD format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y')
WHERE `date` IS NOT NULL AND `date` <> '';

-- Change the column type to DATE
ALTER TABLE layoffs_staging2 
MODIFY COLUMN `date` DATE;

-- ============================================================
-- 6. HANDLE MISSING AND BLANK VALUES
-- Investigate missing layoff figures and standardize blanks.

-- Inspect records with both layoff measures missing
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND (percentage_laid_off IS NULL OR TRIM(percentage_laid_off) = '');

-- Convert blank industry values into NULL
UPDATE layoffs_staging2
SET industry = NULL 
WHERE TRIM(industry) = '';

-- Inspect records with missing industry information
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

-- Check whether the same company has a known industry
SELECT t1.company, t1.industry AS missing_industry, t2.industry AS available_industry
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '') 
AND t2.industry IS NOT NULL;

SELECT company, COUNT(DISTINCT industry) AS industry_count
FROM layoffs_staging2
WHERE industry IS NOT NULL
GROUP BY company
HAVING COUNT(DISTINCT industry) > 1;

-- Fill missing industries using another record for the same company, where a known industry is available.
UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;

-- Remove records where neither layoff measure is available.
-- Rows with only one missing measure are retained.
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND (percentage_laid_off IS NULL OR TRIM(percentage_laid_off) = '');

-- ============================================================
-- 7. CONVERT NUMERIC COLUMNS
-- Use numeric data types for percentage and funding analysis.
-- Validate source values before applying these conversions.

-- Identify percentage values that are not numeric
SELECT DISTINCT percentage_laid_off
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL
AND TRIM(percentage_laid_off) <> ''
AND TRIM(percentage_laid_off) NOT REGEXP '^[0-9]+([.][0-9]+)?$';

-- Convert blank percentage values to NULL
UPDATE layoffs_staging2
SET percentage_laid_off = NULL
WHERE TRIM(percentage_laid_off) = '';

SELECT percentage_laid_off
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL
AND (CAST(percentage_laid_off AS DECIMAL(10,4)) < 0 OR CAST(percentage_laid_off AS DECIMAL(10,4)) > 1);

-- Convert percentage strings to a numeric type.
-- Do this only after investigating any invalid values.
ALTER TABLE layoffs_staging2
MODIFY COLUMN percentage_laid_off DECIMAL(5,4) DEFAULT NULL;

-- Preserve fractional funding amounts
ALTER TABLE layoffs_staging2
MODIFY COLUMN funds_raised_millions DECIMAL(12,2) DEFAULT NULL;
-- ============================================================
-- 8. REMOVE TEMPORARY COLUMNS
-- row_num was needed only to identify duplicate records.
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- ============================================================
-- 9. FINAL VALIDATION
-- Review the cleaned dataset before exploratory analysis.

-- Check final row count and date range
SELECT COUNT(*) AS total_rows, MIN(`date`) AS first_layoff_date, MAX(`date`) AS last_layoff_date
FROM layoffs_staging2;

-- Check for remaining duplicate records
SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions, COUNT(*) AS record_count
FROM layoffs_staging2
GROUP BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions
HAVING COUNT(*) > 1;

-- Check remaining missing values
SELECT SUM(company IS NULL OR TRIM(company) = '') AS missing_company,
SUM(industry IS NULL OR TRIM(industry) = '') AS missing_industry,
SUM(total_laid_off IS NULL) AS missing_total_laid_off,
SUM(percentage_laid_off IS NULL) AS missing_percentage,
SUM(`date` IS NULL) AS missing_date,
SUM(funds_raised_millions IS NULL) AS missing_funding
FROM layoffs_staging2;

-- Inspect the final cleaned table
SELECT *
FROM layoffs_staging2;

