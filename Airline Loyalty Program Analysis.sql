#Airline Loyalty Program Analysis

#Data Cleaning
#Renaming columns for easier reference later
ALTER TABLE customer_loyalty_history RENAME COLUMN `ï»¿LoyaltyNumber` TO LoyaltyNumber;

#Changing data types to match with the correct data type
UPDATE calendar
SET Date = STR_TO_DATE(Date, '%m/%d/%Y');

UPDATE calendar
SET StartofYear = STR_TO_DATE(StartofYear, '%m/%d/%Y');

UPDATE calendar
SET StartofQuarter = STR_TO_DATE(StartofQuarter, '%m/%d/%Y');

UPDATE calendar
SET StartofMonth = STR_TO_DATE(StartofMonth, '%m/%d/%Y');

UPDATE customer_loyalty_history 
SET Salary = NULL 
WHERE Salary NOT REGEXP '^[0-9]+$';
ALTER TABLE customer_loyalty_history MODIFY COLUMN Salary INT;

SELECT DISTINCT CancellationYear FROM customer_loyalty_history;
UPDATE customer_loyalty_history 
SET CancellationYear = NULL 
WHERE CancellationYear NOT REGEXP '^[0-9]+$';
ALTER TABLE customer_loyalty_history MODIFY COLUMN CancellationYear INT;

SELECT DISTINCT CancellationMonth FROM customer_loyalty_history;
UPDATE customer_loyalty_history 
SET CancellationMonth = NULL 
WHERE CancellationMonth NOT REGEXP '^[0-9]+$';
ALTER TABLE customer_loyalty_history MODIFY COLUMN CancellationMonth INT;

#Key Business Questions for Analysis
#Customer Loyalty & Engagement
#How many active vs. inactive members are in the loyalty program?
SELECT COUNT(*)
FROM customer_loyalty_history
WHERE CancellationYear IS NULL;

SELECT COUNT(*)
FROM customer_loyalty_history
WHERE CancellationYear IS NOT NULL;
	#Output= There are 14.670 active members in the loyalty program, and 2.067 inactive members.

#What is the average time between flights for loyal customers vs. occasional travelers?
WITH flight_months AS (
	SELECT LoyaltyNumber, Year, Month
	FROM customer_flight_activity
	WHERE TotalFlights > 0
    ),
monthly_counts AS (
	SELECT LoyaltyNumber, COUNT(DISTINCT CONCAT(Year, '-', Month)) AS active_months
    FROM flight_months
    GROUP BY LoyaltyNumber
	),
traveler_frequency AS (
	SELECT LoyaltyNumber,
    CASE
		WHEN active_months >= 6 THEN 'Loyal'
		ELSE 'Occasional'
	END AS traveler_type
    FROM monthly_counts
	),
flight_gaps AS (
	SELECT f.LoyaltyNumber, t.traveler_type, f.Year, f.Month,
		LEAD(f.Year*12 + f.Month) OVER (PARTITION BY f.LoyaltyNumber ORDER BY f.Year, f.Month) - (f.Year*12 + f.Month) AS gap_in_months
    FROM flight_months f
    JOIN traveler_frequency t ON f.LoyaltyNumber=t.LoyaltyNumber
	)
SELECT traveler_type, ROUND(AVG(gap_in_months), 2) AS `avg_time_between_flights (months)`
FROM flight_gaps
WHERE gap_in_months IS NOT NULL
GROUP BY traveler_type;
	#Output= Average time between flights for loyal customers is 1.59 months, and average time for occasional travelers is 1.67 months.

#What percentage of members never redeem their points?
WITH CTE AS (
	SELECT LoyaltyNumber, SUM(PointsRedeemed) AS points_redeemed
	FROM customer_flight_activity
	GROUP BY LoyaltyNumber)
SELECT (COUNT(DISTINCT CASE WHEN points_redeemed = 0 THEN LoyaltyNumber END) / COUNT(DISTINCT LoyaltyNumber)) * 100
FROM CTE;
	#Output= 31.36% of members never redeemed their points.

#How many members are at risk of churn based on inactivity?
SELECT MAX(Year), MAX(Month)
FROM customer_flight_activity;

WITH CTE AS(
	SELECT LoyaltyNumber, MAX(CONCAT(Year, '-', Month)) AS latest_flown_date
	FROM customer_flight_activity
	WHERE TotalFlights >= 1
	GROUP BY LoyaltyNumber
    )
SELECT COUNT(DISTINCT CASE WHEN latest_flown_date <= '2018-6' THEN LoyaltyNumber END) AS count_risk_of_churn
FROM CTE;
	#Output= 2.219 members haven't flown with the arline in 6 months, therefore are at risk of churn.

#Points & Rewards Analysis
#What is the average number of points earned per flight?
SELECT AVG(TotalFlights/PointsAccumulated) AS avg_points_earned_per_flight
FROM customer_flight_activity;
	#Output= 0.00079 points are earned per flight.

#When do members redeem their points the most?
SELECT Month, SUM(PointsRedeemed) AS total_points_redeemed
FROM customer_flight_activity
GROUP BY Month
ORDER BY total_points_redeemed DESC;
	#Output= Most points are redeemed on months 7 (July), 6 (June), 8 (August) and 12 (December), so basically in the holiday season is when the points are redeemed the most.

#What percentage of accumulated points do members actually redeem?
SELECT (SUM(PointsRedeemed) / SUM(PointsAccumulated)) * 100 AS percentage_redeemed
FROM customer_flight_activity;
	#Output= Only 1.5% of the points accumulated have been redeemed! Which tells us that there's a really low engagement when it comes to members redeeming their points.

#Are inactive members more likely to redeem points?
WITH CTE AS (
	SELECT LoyaltyNumber, MAX(STR_TO_DATE(CONCAT(Year, '-', Month, '-01'), '%Y-%m-%d')) AS last_flight_date
	FROM customer_flight_activity
	WHERE TotalFlights = 0
	GROUP BY LoyaltyNumber
	)
SELECT 
	CASE
		WHEN DATEDIFF('2018-06-01', last_flight_date) > 180 THEN 'Inactive'
		ELSE 'Active'
	END AS member_status,
    SUM(PointsRedeemed) AS total_points_redeemed, SUM(PointsAccumulated) AS total_points_accumulated,
    ROUND((SUM(PointsRedeemed) / NULLIF(SUM(PointsAccumulated), 0)) * 100, 2) AS redemption_rate
FROM customer_flight_activity f
JOIN CTE c ON f.LoyaltyNumber=c.LoyaltyNumber
GROUP BY member_status;
	#Output= Inactive members have a redemption rate of 1.60%, while active members have a redemption rate of 1.54%.

#Customer Segmentation & Behavior
#What are the key differences in behavior between different membership tiers (e.g., Star, Nova, Aurora)?
SELECT LoyaltyCard,
	ROUND(AVG(PointsAccumulated), 2) AS avg_points_accumulated, 
    ROUND(AVG(PointsRedeemed), 2) AS avg_points_redeemed,
    ROUND(SUM(PointsRedeemed) / NULLIF(SUM(PointsAccumulated), 0), 2) AS redemption_ratio,
	SUM(TotalFlights) AS total_flights_per_tier, 
    ROUND(SUM(TotalFlights) / NULLIF(COUNT(DISTINCT h.LoyaltyNumber), 0), 2) AS avg_flights_per_member,
    COUNT(DISTINCT h.LoyaltyNumber) AS member_count,
    COUNT(DISTINCT CASE WHEN CancellationYear IS NOT NULL THEN h.LoyaltyNumber END) AS cancellation_count, 
    ROUND(100 * COUNT(DISTINCT CASE WHEN CancellationYear IS NOT NULL THEN h.LoyaltyNumber END) / NULLIF(COUNT(DISTINCT h.LoyaltyNumber), 0), 2) AS churn_rate,
    ROUND(AVG(CLV), 2) AS avg_customer_lifetime_value
FROM customer_flight_activity a
JOIN customer_loyalty_history h ON a.LoyaltyNumber=h.LoyaltyNumber
GROUP BY LoyaltyCard;
	#Output= All tiers accumulate around 2.000 points on average. Redemption rate is the same on all categories (0.02), meaning members across al tiers redeem points at similar rates. Aurora members take slighlty more flights per member, but the difference is minimal. Churn rates are also very similar, with Aurora having the highest (13.09%). Customer Lifetime Value (CLV) is higher for higher tiers, which is expected considering higher tier members are more likely to spend more and therefore qualifying for better perks.

#Do higher-tier members fly more frequently or redeem more rewards?
SELECT LoyaltyCard,
	ROUND(AVG(PointsAccumulated), 2) AS avg_points_accumulated, 
    ROUND(AVG(PointsRedeemed), 2) AS avg_points_redeemed,
    ROUND(SUM(PointsRedeemed) / NULLIF(SUM(PointsAccumulated), 0), 2) AS redemption_ratio,
	SUM(TotalFlights) AS total_flights_per_tier, 
    ROUND(SUM(TotalFlights) / NULLIF(COUNT(DISTINCT h.LoyaltyNumber), 0), 2) AS avg_flights_per_member
FROM customer_flight_activity a
JOIN customer_loyalty_history h ON a.LoyaltyNumber=h.LoyaltyNumber
GROUP BY LoyaltyCard;
	#Output= Yes, higher tier members flight more frequently and redeem more points than lower tiers, but the difference is almost insignificant between each other.

#Are there regional differences in loyalty program engagement?
SELECT 
    Province,
    SUM(TotalFlights) AS total_flights,
    COUNT(DISTINCT h.LoyaltyNumber) AS total_members,
    COUNT(DISTINCT CASE WHEN CancellationYear IS NOT NULL THEN h.LoyaltyNumber END) AS cancellation_count,
    ROUND((COUNT(DISTINCT CASE WHEN CancellationYear IS NOT NULL THEN h.LoyaltyNumber END) / (COUNT(DISTINCT h.LoyaltyNumber)) * 100), 2) AS cancellation_rate,
    ROUND(AVG(PointsAccumulated), 2) AS avg_points_accumulated,
    ROUND(AVG(PointsRedeemed), 2) AS avg_points_redeemed,
    ROUND((SUM(PointsRedeemed) * 100.0) / NULLIF(SUM(PointsAccumulated), 0), 2) AS redemption_rate
FROM customer_loyalty_history h
JOIN customer_flight_activity a ON h.LoyaltyNumber=a.LoyaltyNumber
GROUP BY Province
ORDER BY cancellation_rate DESC;
	#Output= Prince Edward Island and Manitoba are the regions with the highest cancellation rate (16% in average), and these are also the regions that accumulate the least amount of points (1.800 average points accumulated), however, both have the highest redemption rates (1.7%).

#Which customer demographic (age, location, etc.) is most engaged in the program?
SELECT 
    Province,
    SUM(TotalFlights) AS total_flights,
    COUNT(DISTINCT h.LoyaltyNumber) AS total_members,
    COUNT(DISTINCT CASE WHEN CancellationYear IS NOT NULL THEN h.LoyaltyNumber END) AS cancellation_count,
    ROUND((COUNT(DISTINCT CASE WHEN CancellationYear IS NOT NULL THEN h.LoyaltyNumber END) / (COUNT(DISTINCT h.LoyaltyNumber)) * 100), 2) AS cancellation_rate,
    ROUND(AVG(PointsAccumulated), 2) AS avg_points_accumulated,
    ROUND(AVG(PointsRedeemed), 2) AS avg_points_redeemed,
    ROUND((SUM(PointsRedeemed) * 100.0) / NULLIF(SUM(PointsAccumulated), 0), 2) AS redemption_rate
FROM customer_loyalty_history h
JOIN customer_flight_activity a ON h.LoyaltyNumber=a.LoyaltyNumber
GROUP BY Province
ORDER BY redemption_rate DESC;
	#Output= If we measure most engagement as region with less cancelation rate, then it would be New Brunsbrick, which is also the second highest region on average points redeemed. However if we measure engagement as the region with the highest points redemption rate then it is Prince Edward Island.

#What is the average time a customer stays in the loyalty program before cancelling?
WITH CTE AS (
	SELECT 
		LoyaltyNumber,
		STR_TO_DATE(CONCAT(EnrollmentYear, '-', EnrollmentMonth, '-01'), '%Y-%m-%d') AS EnrollmentDate,
		STR_TO_DATE(CONCAT(CancellationYear, '-', CancellationMonth, '-01'), '%Y-%m-%d') AS CancellationDate
	FROM customer_loyalty_history
	WHERE CancellationYear IS NOT NULL
    )
SELECT ROUND(AVG(DATEDIFF(CancellationDate, EnrollmentDate))) AS avg_time_in_days_before_cancelling
FROM CTE;
	#Output= The average time a customer stays in the program before cancelling is 483 days, which is around a year and a half.

#What is the average flight distance for membership program?
SELECT LoyaltyCard, ROUND(AVG(Distance), 2) AS avg_flight_distance
FROM customer_flight_activity a
JOIN customer_loyalty_history h ON a.LoyaltyNumber=h.LoyaltyNumber
GROUP BY LoyaltyCard
ORDER BY avg_flight_distance DESC;
	#Output= Aurora members (highest membership), have traveled more distance than the other 2 categories, with an average of 1955.07 km. Nova members have an average of 1947.38 km, and lastly Star members have an average of 1930.82 km traveled.

#How does the frequency of flights vary across different membership tiers?
SELECT LoyaltyCard, ROUND(COUNT(TotalFlights), 2) AS flight_frequency
FROM customer_flight_activity a
JOIN customer_loyalty_history h ON a.LoyaltyNumber=h.LoyaltyNumber
GROUP BY LoyaltyCard
ORDER BY flight_frequency DESC;
	#Output= Star members fly more often (178.595 flights), Nova are second (133.265 flights), and finally Aurora (81.076 flights). This answer and the one from the previous question leads us to a new insight, Aurora members fly less often, but at the same time travel the more distance, which tells us that they probably flight internationally mostly.

#How many customers have been inactive for over 6 months?
SELECT COUNT(*)
FROM (
	SELECT LoyaltyNumber, MAX(STR_TO_DATE(CONCAT(Year, '-', Month, '-01'), '%Y-%m-%d')) AS last_flown_date
	FROM customer_flight_activity
	WHERE TotalFlights <> 0
	GROUP BY LoyaltyNumber
	HAVING last_flown_date < '2018-06-01'
    ) AS inactive_members;
    #Output= 810 members have been inactive for 6 months.

#What percentage of inactive customers previously belonged to each membership tier?
SELECT LoyaltyCard, COUNT(*) AS count_inactive_members, ROUND((COUNT(*) / (SELECT COUNT(*) FROM customer_loyalty_history))*100, 2) AS percentage_of_inactive_members
FROM (
	SELECT LoyaltyNumber, MAX(STR_TO_DATE(CONCAT(Year, '-', Month, '-01'), '%Y-%m-%d')) AS last_flown_date
	FROM customer_flight_activity
	WHERE TotalFlights <> 0
	GROUP BY LoyaltyNumber
	HAVING last_flown_date < '2018-06-01'
    ) AS i
JOIN customer_loyalty_history h ON i.LoyaltyNumber=h.LoyaltyNumber
GROUP BY LoyaltyCard
ORDER BY percentage_of_inactive_members DESC;
	#Output= Star membership has the highest percentage of inactive members, with 2.07%. Nova is the second one, with 1.81%. And then Aurora with 0.96%.