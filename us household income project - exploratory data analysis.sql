# US Household Income - EDA
#Exploring the area land by state
SELECT State_name, SUM(ALand), SUM(AWater)
FROM us_household_income
GROUP BY State_name
ORDER BY 2 DESC
LIMIT 10;

#Exploring the water area by state
SELECT State_name, SUM(ALand), SUM(AWater)
FROM us_household_income
GROUP BY State_name
ORDER BY 3 DESC
LIMIT 10;

#Merging both tables
SELECT *
FROM us_household_income u
JOIN us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
;

#Income by State
#Bottom 5 Mean
SELECT u.State_name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income u
JOIN us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.State_Name
ORDER BY 2
LIMIT 5;

#Top 5 Median
SELECT u.State_name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income u
JOIN us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.State_Name
ORDER BY 2 DESC
LIMIT 5;

#Top 5 Median
SELECT u.State_name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income u
JOIN us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.State_Name
ORDER BY 3 DESC
LIMIT 5;

#Bottom 5 Median
SELECT u.State_name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income u
JOIN us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.State_Name
ORDER BY 3
LIMIT 5;

#Income by Type
#Top 5 Mean
SELECT u.Type, COUNT(Type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income u
JOIN us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.Type
ORDER BY 3 DESC
LIMIT 5
;

#Bottom 5 Mean
SELECT u.Type, COUNT(Type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income u
JOIN us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.Type
ORDER BY 3
LIMIT 5
;

#Top 5 Median
SELECT u.Type, COUNT(Type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income u
JOIN us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.Type
ORDER BY 4 DESC
LIMIT 5
;

#Bottom 5 Median
SELECT u.Type, COUNT(Type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income u
JOIN us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.Type
ORDER BY 4
LIMIT 5
;

#Income by Cities
#Highest incomes
SELECT u.State_Name, City, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income u
JOIN us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.State_Name, City
ORDER BY 3 DESC;

#Lowest incomes
SELECT u.State_Name, City, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_household_income u
JOIN us_household_income_statistics us
	ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.State_Name, City
ORDER BY 3;


