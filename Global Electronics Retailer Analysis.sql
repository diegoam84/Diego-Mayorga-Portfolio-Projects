#Global Electronics Retailer Analysis

#Data Cleaning
#Checking for duplicates in all tables
SELECT DISTINCT CustomerKey, COUNT(CustomerKey)
FROM customers
GROUP BY CustomerKey
HAVING COUNT(CustomerKey)>1;

SELECT DISTINCT ProductKey, COUNT(ProductKey)
FROM products
GROUP BY ProductKey
HAVING COUNT(ProductKey)>1;

SELECT *
FROM sales
WHERE `Order Number` IN (
	SELECT DISTINCT `Order Number`
	FROM sales
	GROUP BY `Order Number`
	HAVING COUNT(`Order Number`)>1);

SELECT DISTINCT StoreKey, COUNT(StoreKey)
FROM stores
GROUP BY Storekey
HAVING COUNT(StoreKey)>1;

#Renaming columns for easier reference later
ALTER TABLE sales RENAME COLUMN `Order Number` TO OrderNumber;
ALTER TABLE sales RENAME COLUMN `Line Item` TO LineItem;
ALTER TABLE sales RENAME COLUMN `Order Date` TO OrderDate;
ALTER TABLE sales RENAME COLUMN `Delivery Date` TO DeliveryDate;
ALTER TABLE sales RENAME COLUMN `Currency Code` TO CurrencyCode;
ALTER TABLE customers RENAME COLUMN `State Code` TO StateCode;
ALTER TABLE customers RENAME COLUMN `Zip Code` TO ZipCode;
ALTER TABLE products RENAME COLUMN `Product Name` TO ProductName;
ALTER TABLE products RENAME COLUMN `Unit Cost USD` TO UnitCostUSD;
ALTER TABLE products RENAME COLUMN `Unit Price USD` TO UnitPriceUSD;
ALTER TABLE stores RENAME COLUMN `Square Meters` TO SquareMeters;
ALTER TABLE stores RENAME COLUMN `Open Date` TO OpenDate;

#Standardizing data for later calculations
UPDATE products
SET UnitCostUSD = REGEXP_REPLACE(UnitCostUSD, '\\$', '');

UPDATE products
SET UnitPriceUSD = REGEXP_REPLACE(UnitPriceUSD, '\\$', '');

#Assigning Correct Data Types
UPDATE customers
SET Birthday = STR_TO_DATE(Birthday, '%m/%d/%Y');

UPDATE sales
SET OrderDate = STR_TO_DATE(OrderDate, '%m/%d/%Y');

UPDATE sales
SET DeliveryDate = NULL
WHERE DeliveryDate = '';

UPDATE sales
SET DeliveryDate = STR_TO_DATE(DeliveryDate, '%m/%d/%Y');

UPDATE stores
SET OpenDate = STR_TO_DATE(OpenDate, '%m/%d/%Y');

UPDATE exchange_rates
SET Date = STR_TO_DATE(Date, '%m/%d/%Y');

ALTER TABLE products MODIFY COLUMN UnitCostUSD DECIMAL(10,2);
ALTER TABLE products MODIFY COLUMN UnitPriceUSD DECIMAL(10,2);

#Business Questions
#Sales Performance & Trends
#What are the total sales and revenue trends over time (daily, monthly, yearly)?
SELECT OrderDate, SUM(UnitPriceUSD) AS total_sales, SUM((UnitPriceUSD-UnitCostUSD)*quantity) AS revenue
FROM sales s
JOIN products p ON s.ProductKey=p.ProductKey
GROUP BY OrderDate
ORDER BY revenue DESC;
	#Output= Days where we made the highest profit were on December 21, 22, and 26 of 2019.

SELECT MONTH(OrderDate) AS month, YEAR(OrderDate) AS year, SUM(UnitPriceUSD) AS total_sales, SUM((UnitPriceUSD-UnitCostUSD)*quantity) AS revenue
FROM sales s
JOIN products p ON s.ProductKey=p.ProductKey
GROUP BY MONTH(OrderDate), YEAR(OrderDate)
ORDER BY revenue DESC;
	#Output= And best months in terms of revenue were December 2019 and 2018, February 2020 and 2019, and January 2020.

SELECT YEAR(OrderDate) AS year, SUM(UnitPriceUSD) AS total_sales, SUM((UnitPriceUSD-UnitCostUSD)*quantity) AS revenue
FROM sales s
JOIN products p ON s.ProductKey=p.ProductKey
GROUP BY YEAR(OrderDate)
ORDER BY revenue DESC;
	#Output= The best year was 2019, were we made a revenue of $10 millions USD, second was 2018 with a revenue of $7 millions USD.

SELECT YEAR(OrderDate) AS year, SUM(UnitPriceUSD) AS total_sales, SUM((UnitPriceUSD-UnitCostUSD)*quantity) AS revenue
FROM sales s
JOIN products p ON s.ProductKey=p.ProductKey
GROUP BY YEAR(OrderDate)
ORDER BY YEAR(OrderDate);
	#Output= Overall 2016 and 2017 were the lowest years in revenue (average 4.2 millions), and 2018 and 2019 it increased to be the best ones (average 8.5 millions), in 2020 and 2021 the revenue went down a little bit (average 7 millions).

#Which stores generate the highest and lowest revenue?
SELECT s.StoreKey, st.State, st.Country, SUM((UnitPriceUSD-UnitCostUSD)*quantity) AS revenue
FROM sales s
JOIN products p ON s.ProductKey=p.ProductKey
LEFT JOIN stores st ON s.StoreKey=st.StoreKey
GROUP BY s.StoreKey, st.State, st.Country
ORDER BY revenue DESC;
	#Output= Online selling is the best one by far (6.6 millions), but regarding stores, the best 3 are: 55 Nevada, US. 50 Kansas, US., and 54 Nebraska, US. The stores with the lowest revenue are: 2 Northern Territory, Australia., 14 Franche-Comtac, France., 13 Corse, France.

#What are the top-selling products, and which products underperform?
SELECT p.ProductKey, p.ProductName, p.Category, SUM((UnitPriceUSD-UnitCostUSD)*quantity) AS revenue
FROM sales s
JOIN products p ON s.ProductKey=p.ProductKey
GROUP BY p.ProductKey, p.ProductName, p.Category
ORDER BY revenue DESC;
	#Output= Top selling products are computers ('WWI Desktop PC2.33 X2330 Black', 'Adventure Works Desktop PC2.33 XD233 Silver', 'Adventure Works Desktop PC2.33 XD233 Brown'). Top underperform products are USBs ('SV USB Data Cable E600 Silver', 'SV USB Sync Charge Cable E700 Silver') and a 'Litware 80mm Dual Ball Bearing Case Fan E1001 Green'.

#Are there country differences in sales performance?
SELECT st.Country, SUM((UnitPriceUSD-UnitCostUSD)*quantity) AS revenue
FROM sales s
JOIN products p ON s.ProductKey=p.ProductKey
JOIN stores st ON s.StoreKey=st.StoreKey
GROUP BY st.Country
ORDER BY revenue DESC;
	#Output= There is a big difference between the top 1 and 2, United States has a revenue of 13.9 millions, while United Kingdom has a revenue of 3.3 million. And the countries with the lowest revenue are France ($725.174) and Netherlands ($937.765).

#Customer Insights
#What is the average purchase frequency per customer?
SELECT ROUND(AVG(order_count), 2) AS average_purchase_frequency
FROM (
    SELECT CustomerKey, COUNT(DISTINCT OrderNumber) AS order_count
    FROM sales
    GROUP BY CustomerKey
	) AS customer_orders;
	#Output= Average purchase frequency per customer is 2.21

#Do loyal customers (repeat buyers) generate more revenue than one-time buyers?
SELECT ROUND(AVG(revenue), 2) AS average_revenue
FROM (
	SELECT CustomerKey, SUM((UnitPriceUSD-UnitCostUSD)*quantity) AS revenue
	FROM sales s
	JOIN products p ON s.ProductKey=p.ProductKey
	WHERE CustomerKey IN (
		SELECT CustomerKey
		FROM sales
		GROUP BY CustomerKey
		HAVING COUNT(DISTINCT OrderNumber) > 1
		)
	GROUP BY CustomerKey) AS loyal_customers;

SELECT ROUND(AVG(revenue), 2) AS average_revenue
FROM (
	SELECT CustomerKey, SUM((UnitPriceUSD-UnitCostUSD)*quantity) AS revenue
	FROM sales s
	JOIN products p ON s.ProductKey=p.ProductKey
	WHERE CustomerKey IN (
		SELECT CustomerKey
		FROM sales
		GROUP BY CustomerKey
		HAVING COUNT(DISTINCT OrderNumber) <= 1
		)
	GROUP BY CustomerKey) AS one_time_customers;
    #Output= Average revenue of loyal customers is $3.700 USD, and average revenue of one-time customers is $1.246 USD. So loyal customers indeed generate more revenue than one-time customers.
    
#What customer segments (e.g., age groups, locations) contribute most to revenue?
ALTER TABLE customers
ADD COLUMN Age INT;
UPDATE customers
SET Age = YEAR(NOW())-YEAR(Birthday);

WITH CTE AS (
	SELECT *,
	CASE
		WHEN Age BETWEEN 20 AND 30 THEN '20-30'
		WHEN Age BETWEEN 31 AND 40 THEN '31-40'
		WHEN Age BETWEEN 41 AND 50 THEN '41-50'
		WHEN Age BETWEEN 51 AND 60 THEN '51-60'
		WHEN Age BETWEEN 61 AND 70 THEN '61-70'
		WHEN Age BETWEEN 71 AND 80 THEN '71-80'
		WHEN Age BETWEEN 81 AND 90 THEN '81-90'
	END AS AgeGroup
	FROM customers
    )
SELECT AgeGroup, SUM((UnitPriceUSD-UnitCostUSD)*Quantity) AS revenue, COUNT(*) AS count
FROM CTE
JOIN sales s ON CTE.CustomerKey=s.CustomerKey
JOIN products p ON s.ProductKey=p.ProductKey
GROUP BY AgeGroup
ORDER BY revenue DESC;
	#Output= Age Group 31-40 is our highest revenue group (5 millions), then groups 51-60, 71-80, 61-70, 41-50, 81-90 generate 4.8 millions each.

SELECT Gender, SUM((UnitPriceUSD-UnitCostUSD)*Quantity) AS revenue, COUNT(*) AS count
FROM customers c
JOIN sales s ON c.CustomerKey=s.CustomerKey
JOIN products p ON s.ProductKey=p.ProductKey
GROUP BY Gender
ORDER BY revenue DESC;
	#Output= Men generate a little bit more revenue (16.6 millions) to us, than women (16 millions), but not by much.

SELECT Continent, SUM((UnitPriceUSD-UnitCostUSD)*Quantity) AS revenue, COUNT(*) AS count
FROM customers c
JOIN sales s ON c.CustomerKey=s.CustomerKey
JOIN products p ON s.ProductKey=p.ProductKey
GROUP BY Continent
ORDER BY revenue DESC;
	#Output= North America is the continent with the highest revenue (20 millions), very big difference compared to the second one which is Europe, with 10.8 millions, and lastly Australia with only 1.5 millions.

SELECT Country, State, SUM((UnitPriceUSD-UnitCostUSD)*Quantity) AS revenue, COUNT(*) AS count
FROM customers c
JOIN sales s ON c.CustomerKey=s.CustomerKey
JOIN products p ON s.ProductKey=p.ProductKey
GROUP BY Country, State
ORDER BY revenue DESC;
	#Output= States where we get the most revenue from are California, Texas and New York In US. Ontario in Canada. And Freistaat Bayern in Germany.

#Are there customers who haven’t made a purchase in a long time (churn analysis)?
WITH CTE AS(
	SELECT CustomerKey, MAX(OrderDate)
	FROM sales
	GROUP BY CustomerKey
	HAVING MAX(OrderDate) < DATE_SUB(NOW(), INTERVAL 6 MONTH)
    )
SELECT COUNT(*) AS count, (SELECT COUNT(DISTINCT CustomerKey) FROM customers) AS total_customers,
(CAST(COUNT(*) AS DECIMAL(10, 2)) / (SELECT COUNT(DISTINCT CustomerKey) FROM customers)) *100 AS churn_percentage
FROM CTE;
	#Output= 11.887 customers haven't made a purchase in 6 months. Churn percentage is 77.9%.

#What is the average order value per customer segment?
WITH CTE AS (
	SELECT *,
	CASE
		WHEN Age BETWEEN 20 AND 30 THEN '20-30'
		WHEN Age BETWEEN 31 AND 40 THEN '31-40'
		WHEN Age BETWEEN 41 AND 50 THEN '41-50'
		WHEN Age BETWEEN 51 AND 60 THEN '51-60'
		WHEN Age BETWEEN 61 AND 70 THEN '61-70'
		WHEN Age BETWEEN 71 AND 80 THEN '71-80'
		WHEN Age BETWEEN 81 AND 90 THEN '81-90'
	END AS AgeGroup
	FROM customers
    )
SELECT AgeGroup, AVG((UnitPriceUSD-UnitCostUSD)*Quantity) AS avg_revenue, COUNT(*) AS count
FROM CTE
JOIN sales s ON CTE.CustomerKey=s.CustomerKey
JOIN products p ON s.ProductKey=p.ProductKey
GROUP BY AgeGroup
ORDER BY avg_revenue DESC;
	#Output= Highest average revenue comes from age groups 81-90 and 31-40 (average revenue $534).

SELECT Gender, AVG((UnitPriceUSD-UnitCostUSD)*Quantity) AS avg_revenue, COUNT(*) AS count
FROM customers c
JOIN sales s ON c.CustomerKey=s.CustomerKey
JOIN products p ON s.ProductKey=p.ProductKey
GROUP BY Gender
ORDER BY avg_revenue DESC;
	#Output= Men's average revenue is $522, and women is $516.

SELECT Continent, AVG((UnitPriceUSD-UnitCostUSD)*Quantity) AS avg_revenue, COUNT(*) AS count
FROM customers c
JOIN sales s ON c.CustomerKey=s.CustomerKey
JOIN products p ON s.ProductKey=p.ProductKey
GROUP BY Continent
ORDER BY avg_revenue DESC;
	#Output= Australia is the continent with the highest avergae revenue $543, second one is Europe, with $521, and lastly North America with $516.

SELECT Country, State, AVG((UnitPriceUSD-UnitCostUSD)*Quantity) AS avg_revenue, COUNT(*) AS count
FROM customers c
JOIN sales s ON c.CustomerKey=s.CustomerKey
JOIN products p ON s.ProductKey=p.ProductKey
GROUP BY Country, State
HAVING count > 20
ORDER BY avg_revenue DESC;
	#Output= States where average revenue is the highest are Nuoro and Pisa in Italy. Uk had a few with hgher average, but it was due to the fact that there were only 20 purchases or less made.

#Operational Efficiency
#What is the average delivery time, and which regions experience the most delays?
WITH CTE AS(
	SELECT OrderNumber, City, State, Country, DATEDIFF(DeliveryDate, OrderDate) AS Delivery_delay_in_days
	FROM sales s
	LEFT JOIN customers c ON s.CustomerKey=c.CustomerKey
    WHERE DeliveryDate IS NOT NULL
    )
SELECT ROUND(AVG(Delivery_delay_in_days), 1) AS average_delivery_delay
FROM CTE;
	#Output= Average delivery delay is 4.5 days.

WITH CTE AS(
	SELECT OrderNumber, City, State, Country, DATEDIFF(DeliveryDate, OrderDate) AS Delivery_delay_in_days
	FROM sales s
	LEFT JOIN customers c ON s.CustomerKey=c.CustomerKey
    WHERE DeliveryDate IS NOT NULL
    )
SELECT City, State, Country, ROUND(AVG(Delivery_delay_in_days), 1) AS average_delivery_delay
FROM CTE
GROUP BY City, State, Country
ORDER BY average_delivery_delay DESC;
	#Output= Cities with the highest delivery delays are Waynesboro, Virginia, US (17 days), Aloha, Oregon, US (15 days), and Bowcombe, Isle of Wight, UK (13 days).

WITH CTE AS(
	SELECT OrderNumber, City, State, Country, DATEDIFF(DeliveryDate, OrderDate) AS Delivery_delay_in_days
	FROM sales s
	LEFT JOIN customers c ON s.CustomerKey=c.CustomerKey
    WHERE DeliveryDate IS NOT NULL
    )
SELECT State, Country, ROUND(AVG(Delivery_delay_in_days), 1) AS average_delivery_delay
FROM CTE
GROUP BY State, Country
ORDER BY average_delivery_delay DESC;
	#Output= States with the highest delivery delays are Isle of Wight (13 days), East Dorset (11 days), Relgate and Banstead (10 days), Selby (10 days), Plymouth (9 days) all states in UK.

#Are there certain product categories that have longer delivery times?
WITH CTE AS(
	SELECT Category, ProductName, Brand, DATEDIFF(DeliveryDate, OrderDate) AS Delivery_delay_in_days
	FROM sales s
	LEFT JOIN products p ON s.ProductKey=p.ProductKey
	WHERE DeliveryDate IS NOT NULL
    )
SELECT Category, ROUND(AVG(Delivery_delay_in_days), 2) AS average_delivery_delay
FROM CTE
GROUP BY Category
ORDER BY average_delivery_delay DESC;
	#Output= TV and Video has the highest average delay (4.89 days), followed by Home Appliances (4.77 days), and Music, Movies and Audio Books (4.59 days)

WITH CTE AS(
	SELECT Category, ProductName, Brand, DATEDIFF(DeliveryDate, OrderDate) AS Delivery_delay_in_days
	FROM sales s
	LEFT JOIN products p ON s.ProductKey=p.ProductKey
	WHERE DeliveryDate IS NOT NULL
    )
SELECT Category, Brand, ROUND(AVG(Delivery_delay_in_days), 2) AS average_delivery_delay
FROM CTE
GROUP BY Category, Brand
ORDER BY average_delivery_delay DESC;
	#Output= Brands with the highest average delay are Litware (5.27 days), followed by Wide World Importers (5.25 days), and Northwind Traders (5.04 days)

#Which stores experience the highest order volume?
SELECT s.StoreKey, st.State, COUNT(DISTINCT OrderNumber) AS order_volume
FROM sales s
LEFT JOIN stores st ON s.StoreKey=st.StoreKey
GROUP BY s.StoreKey, st.State
ORDER BY order_volume DESC;
	#Output= Highest order volume comes from the website (5.580 orders), Northwest Territories (658 orders), and then Nebraska (629 orders).