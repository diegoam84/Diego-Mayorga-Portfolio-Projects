# US Household Income Data Cleaning

#Changing the id column name (bad import)
SELECT *
FROM us_household_income_statistics;

ALTER TABLE us_household_income_statistics RENAME COLUMN `ï»¿id` TO id;

# Checking data integrity
SELECT COUNT(id)
FROM us_household_income_statistics;

SELECT COUNT(id)
FROM us_household_income;

#Checking for duplicates in household income
SELECT id, COUNT(id)
FROM us_household_income
GROUP BY id
HAVING COUNT(id) > 1;

#Removing duplicates in household income
DELETE FROM us_household_income
WHERE row_id IN (
				SELECT row_id
				FROM (
					SELECT row_id, id,
					ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) AS row_num
					FROM us_household_income
					) AS duplicates
				WHERE row_num > 1);
                
#Checking for duplicates in household income statistics
SELECT id, COUNT(id)
FROM us_household_income_statistics
GROUP BY id
HAVING COUNT(id) > 1;

#Correcting state name inconsistencies
SELECT State_Name, COUNT(State_Name)
FROM us_household_income
GROUP BY State_Name
ORDER BY COUNT(State_Name)
;

UPDATE us_household_income
SET State_Name = 'Georgia'
WHERE State_Name = 'georia';

UPDATE us_household_income
SET State_Name = 'Alabama'
WHERE State_Name = 'alabama';

#Checking for inconsistencies in state_ab
SELECT DISTINCT State_ab
FROM us_household_income
ORDER BY 1;

#Checking for nulls in place
SELECT *
FROM us_household_income
WHERE Place = ''
ORDER BY 1;

SELECT *
FROM us_household_income
WHERE County = 'Autauga County'
ORDER BY 1;

UPDATE us_household_income
SET Place = 'Autaugaville'
WHERE County = 'Autauga County' AND City = 'Vinemont';

#Checking for inconsistencies in type
SELECT Type, COUNT(Type)
FROM us_household_income
GROUP BY Type;

UPDATE us_household_income
SET Type = 'Borough'
WHERE Type = 'Boroughs';