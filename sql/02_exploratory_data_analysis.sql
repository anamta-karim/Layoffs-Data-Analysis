-- PROJECT: Layoffs Data Analysis
-- PURPOSE: Exploratory Data Analysis (EDA)

-- ============================================================
-- 1. DATASET OVERVIEW
-- Inspect the cleaned dataset and its date coverage

-- Inspect the records
SELECT * 
FROM layoffs_staging2;

-- Check the number of records and date range
SELECT COUNT(*) AS total_records, MIN(`date`) AS first_layoff_date, 
MAX(`date`) AS last_layoff_date
FROM layoffs_staging2;

-- ============================================================
-- 2. OVERALL LAYOFF STATISTICS
-- Understand the scale of reported layoffs

-- Maximum layoffs and maximum percentage in a single record
SELECT MAX(total_laid_off) AS max_total_laid_off, MAX(percentage_laid_off) AS max_percentage_laid_off
FROM layoffs_staging2;

-- Records reporting 100% layoffs
-- Ordered by funding raised, highest first
SELECT company, industry, total_laid_off, percentage_laid_off, funds_raised_millions, `date`
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- ============================================================
-- 3. LAYOFFS BY COMPANY
-- Identify companies with the highest total recorded layoffs

-- Total layoffs by company
SELECT company, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;

-- ============================================================
-- 4. LAYOFFS BY INDUSTRY, COUNTRY, AND STAGE
-- Compare recorded layoffs across categories

-- Total layoffs by industry
SELECT industry, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY total_laid_off DESC;

-- Total layoffs by country
SELECT country, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;

-- Total layoffs by company stage
SELECT stage, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY stage
ORDER BY total_laid_off DESC;

-- ============================================================
-- 5. YEARLY AND MONTHLY TRENDS
-- Examine how reported layoffs changed over time

-- Total layoffs by year
SELECT YEAR(`date`) AS layoff_year, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY YEAR(`date`)
ORDER BY layoff_year;

-- Total layoffs by month
SELECT DATE_FORMAT(`date`, '%Y-%m') AS month, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY DATE_FORMAT(`date`, '%Y-%m')
ORDER BY month;

-- Rolling cumulative total of reported layoffs by month
WITH Monthly_Layoffs AS (
SELECT DATE_FORMAT(`date`, '%Y-%m') AS `month`, SUM(total_laid_off) as monthly_layoffs
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY DATE_FORMAT(`date`, '%Y-%m')
)
SELECT `month`, monthly_layoffs, SUM(monthly_layoffs) OVER(ORDER BY `month`) as rolling_total
FROM Monthly_Layoffs
ORDER BY month;

-- ============================================================
-- 6. COMPANY-LEVEL YEARLY RANKINGS
-- Find the companies with the highest layoffs in each year

-- Rank companies by total layoffs within each year
WITH Company_Year AS (
SELECT company, YEAR(`date`) AS layoff_year, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY company, YEAR(`date`)
), 
Company_Year_Rank AS (
SELECT company, layoff_year, total_laid_off, 
DENSE_RANK() OVER(PARTITION BY layoff_year ORDER BY total_laid_off DESC) AS ranking
FROM Company_Year
)
SELECT company, layoff_year, total_laid_off, ranking
FROM Company_Year_Rank
WHERE ranking <= 5
ORDER BY layoff_year, ranking;

