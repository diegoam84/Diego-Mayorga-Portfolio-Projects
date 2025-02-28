# World Life Expectancy Project (Exploratory Data Analysis)
SELECT *
FROM world_life_expectancy;

# Reviewing life expectancy increases
SELECT Country, 
MIN(`Life expectancy`) AS min_life_expectancy, 
MAX(`Life expectancy`) AS max_life_expectancy,
ROUND(MAX(`Life expectancy`)-MIN(`Life expectancy`),1) AS life_increase_over_15_years
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life expectancy`) <> 0 AND MAX(`Life expectancy`) <> 0
ORDER BY life_increase_over_15_years DESC
;

# Reviewing life expectancy least increase
SELECT Country, 
MIN(`Life expectancy`) AS min_life_expectancy, 
MAX(`Life expectancy`) AS max_life_expectancy,
ROUND(MAX(`Life expectancy`)-MIN(`Life expectancy`),1) AS life_increase_over_15_years
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life expectancy`) <> 0 AND MAX(`Life expectancy`) <> 0
ORDER BY life_increase_over_15_years ASC;

# Average life expectancy by year
SELECT Year, ROUND(AVG(`Life expectancy`),2) AS avg_life_expectancy
FROM world_life_expectancy
GROUP BY Year
HAVING MIN(`Life expectancy`) <> 0 AND MAX(`Life expectancy`) <> 0
ORDER BY Year;

# Checking correlation between life expectancy and GDP
SELECT country, ROUND(AVG(`Life expectancy`),1) AS life_exp, ROUND(AVG(GDP),2) AS avg_GDP
FROM world_life_expectancy
GROUP BY country
HAVING life_exp > 0 AND avg_GDP > 0
ORDER BY avg_GDP;

# Differences on life expectancies between high GDP and low GDP countries
SELECT 
SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) AS high_GDP_count,
ROUND(AVG(CASE WHEN GDP >= 1500 THEN `Life expectancy` ELSE NULL END),2) AS high_GDP_life_expectancy,
SUM(CASE WHEN GDP <= 1500 THEN 1 ELSE 0 END) AS low_GDP_count,
ROUND(AVG(CASE WHEN GDP <= 1500 THEN `Life expectancy` ELSE NULL END),2) AS low_GDP_life_expectancy
FROM world_life_expectancy
;

# Differences on life expectancies between developed and developing countries
SELECT Status, COUNT(DISTINCT Country), ROUND(AVG(`Life expectancy`),1) AS avg_life_expectancy
FROM world_life_expectancy
GROUP BY Status;

# Checking BMI by country vs life expectancy
SELECT country, ROUND(AVG(`Life expectancy`),1) AS life_exp, ROUND(AVG(BMI),2) AS BMI
FROM world_life_expectancy
GROUP BY country
HAVING life_exp > 0 AND BMI > 0
ORDER BY BMI DESC;

# Adult mortality by country vs life expectancy
SELECT Country, 
Year,
`Life expectancy`,
`Adult Mortality`,
SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY Year) AS rolling_total
FROM world_life_expectancy
WHERE Country LIKE 'Canada'
;