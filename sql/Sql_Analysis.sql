<<<<<<< HEAD
SELECT
	*
FROM
	DIM_CUSTOMER;

SELECT
	*
FROM
	DIM_DELIVERY_PARTNER;

SELECT
	*
FROM
	dim_restaurant;

SELECT
	*
FROM
	FACT_ORDER where ;

--Q1 Monthly Orders: Compare total orders across pre-crisis (Jan–May 2025) vs crisis
--(Jun–Sep 2025). How severe is the decline?
WITH
	CTE AS (
		SELECT
			COUNT(
				CASE
					WHEN DATE (ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN ORDER_ID
				END
			) AS PRE_CRISIS,
			COUNT(
				CASE
					WHEN DATE (ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN ORDER_ID
				END
			) AS POST_CRISIS
		FROM
			FACT_ORDER
	)
SELECT
	PRE_CRISIS,
	POST_CRISIS,
	ROUND(
		100 * (PRE_CRISIS - POST_CRISIS) / PRE_CRISIS::NUMERIC,
		2
	) AS DECLINE_PERCENTAGE
FROM
	CTE;

--Q2. Which top 5 city groups experienced the highest percentage decline in orders
--during the crisis period compared to the pre-crisis period?
WITH
	CTE AS (
		SELECT
			C.CITY AS CITY,
			COUNT(
				CASE
					WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN F.ORDER_ID
				END
			) AS PRE_CRISIS,
			COUNT(
				CASE
					WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN F.ORDER_ID
				END
			) AS POST_CRISIS
		FROM
			FACT_ORDER F
			INNER JOIN DIM_CUSTOMER C ON F.CUSTOMER_ID = C.CUSTOMER_ID
		GROUP BY
			CITY
	)
SELECT
	CITY,
	PRE_CRISIS,
	POST_CRISIS,
	ROUND(
		(PRE_CRISIS - POST_CRISIS) / PRE_CRISIS::NUMERIC * 100,
		2
	) AS DECLINE_PERCENTAGE
FROM
	CTE
ORDER BY
	DECLINE_PERCENTAGE DESC
LIMIT
	5;

--Q3 Among restaurants with at least 50 pre-crisis orders, which top 10 high-volume
--restaurants experienced the largest percentage decline in order counts during
--the crisis period?

 
WITH
CTE AS (
SELECT
r.restaurant_name as restaurant ,
COUNT(
CASE
WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN F.ORDER_ID
	END
) AS PRE_CRISIS,
COUNT(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN F.ORDER_ID
	END
	) AS POST_CRISIS
	FROM
	FACT_ORDER F
	 JOIN dim_restaurant r ON F.restaurant_id = r.restaurant_id
	 	GROUP BY r.restaurant_name 
			)

select   restaurant, pre_crisis, post_crisis,ROUND(
		(PRE_CRISIS - POST_CRISIS) / PRE_CRISIS::NUMERIC * 100,
		2
	) AS DECLINE_PERCENTAGE from cte where pre_crisis>=50 order by decline_percentage desc limit 10;

--Q4 Cancellation Analysis: What is the cancellation rate trend pre-crisis vs crisis,
--and which cities are most affected
	with cte as(
	SELECT
	r.city,
	COUNT(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN F.ORDER_ID
		END
	) AS PRE_CRISIS,
	COUNT(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'
	and F.is_cancelled='Y' THEN F.ORDER_ID
		END
	) AS PRE_CRISIS_CANCELLED,
	COUNT(
		CASE
		WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN F.ORDER_ID
		END
		) AS POST_CRISIS,
		COUNT(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP)  BETWEEN '2025-06-01' AND '2025-09-30' 
	and F.is_cancelled='Y' THEN F.ORDER_ID
		END
	) AS POST_CRISIS_CANCELLED
		FROM
		FACT_ORDER F  JOIN dim_restaurant r on r.restaurant_id=F.restaurant_id 
		group by r.city),
	cancellation_rates as(
	select city,round(PRE_CRISIS_CANCELLED/PRE_CRISIS::decimal*100,2) as pre_crisis_rate,
	round(POST_CRISIS_CANCELLED/POST_CRISIS::decimal*100 , 2) as
	post_crisis_rate from cte
		)
	select city,pre_crisis_rate,post_crisis_rate,post_crisis_rate - pre_crisis_rate as rate_change  
	from cancellation_rates order by rate_change desc
	 limit 10;

/*5. Delivery SLA: Measure average delivery time across phases. Did SLA
compliance worsen significantly in the crisis period?*/
--
with cte as(
select case
when date(o.order_timestamp) between '2025-06-01' AND '2025-09-30' then 'post_crisis'
else 'pre_crisis' end as time_period,
count(*) as total_orders,
round(avg(p.actual_delivery_time_mins),2) as avg_actual_delivery,
round(avg(p.expected_delivery_time_mins),2) as avg_expected_delivery,
sum(case when p.actual_delivery_time_mins<=p.expected_delivery_time_mins then 1 else 0 end)
as sla_compliant_orders
from 
fact_delivery_performance p join fact_order o on p.order_id=o.order_id
group by time_period order by time_period desc)

select time_period,avg_actual_delivery,avg_expected_delivery,
round(sla_compliant_orders/total_orders::decimal*100,2) as compliant_percentage from cte;


/*6. Ratings Fluctuation: Track average customer rating month-by-month. Which
months saw the sharpest drop?*/

 select to_char( review_timestamp,'Month') as months ,extract('month' from review_timestamp) as month_num,
 round(avg(rating),2) from fact_ratings group by months ,month_num
 order by month_num asc;

/*7. Sentiment Insights: During the crisis period, identify the most frequently
occurring negative keywords in customer review texts. (Hint: Use a Word Cloud
visual in Power BI to visualize the find*/

 SELECT unnest(ARRAY[
        'late', 'delay', 'cold', 'slow', 'bad', 'wrong','safety','small'
        'rude', 'missing', 'poor', 'unacceptable','average','less','issue','stale',
		'not','worst','terrible','horrible','okay'
    ]) AS word;

SELECT (review_text),count(review_text) as occurence
FROM fact_ratings
WHERE review_timestamp BETWEEN '2025-06-01' AND '2025-09-30'
group by review_text order by occurence desc ;


/*8.Revenue Impact: Estimate revenue loss from pre-crisis vs crisis (based on
subtotal, discount, and delivery fee).*/



with cte as(
select sum(case
when date(o.order_timestamp) between '2025-06-01' AND '2025-09-30' 
then i.line_total+o.delivery_fee end) as post_crisis_revenue,
sum(case
when date(o.order_timestamp) between '2025-01-01' AND '2025-05-31' 
then i.line_total+o.delivery_fee end) as pre_crisis_revenue
from fact_order o
join fact_order_items i on i.order_id=o.order_id
)

select pre_crisis_revenue,post_crisis_revenue,round(
(pre_crisis_revenue-post_crisis_revenue)/pre_crisis_revenue *100) as loss_percentage
from cte;


/*9. Loyalty Impact: Among customers who placed five or more orders before the
crisis, determine how many stopped ordering during the crisis, and out of those,
how many had an average rating above 4.5?*/


WITH
CTE AS (
SELECT
c.customer_id ,
COUNT(
CASE
WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN F.ORDER_ID
	END
) AS PRE_CRISIS,
COUNT(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN F.ORDER_ID
	END
	) AS POST_CRISIS
	FROM
	FACT_ORDER F
	 JOIN dim_customer c ON F.customer_id = c.customer_id
		 GROUP BY c.customer_id
	 order by pre_crisis desc
	)

	--select count(*) from cte where pre_crisis>=5 and post_crisis=0 --49 customers who stopped ordering
	
select r.customer_id as lost_customers,round( avg(r.rating),4) as avg_rating
	from cte join fact_ratings r on cte.customer_id=r.customer_id
	where pre_crisis>=5 and post_crisis=0 
	group by r.customer_id having avg(r.rating)>=4.5
	order by avg_rating desc
	;--30 out of 49 has 4.5+ rating



/*10. Customer Lifetime Decline: Which high-value customers (top 5% by total
spend before the crisis) showed the largest drop in order frequency and ratings
during the crisis? What common patterns (e.g., location, cuisine preference,
delivery delays) do they share?*/


WITH
CTE AS (
SELECT
c.customer_id ,C.CITY,ROUND(AVG(R.RATING),2) AS RATING,
SUM(
CASE
WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN F.TOTAL_AMOUNT
	END
) AS PRE_CRISIS_TOTAL,
COUNT(
CASE
WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN F.ORDER_ID
	END
) AS PRE_CRISIS_ORDERS,
AVG(
CASE
WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN R.RATING
	END
) AS PRE_CRISIS_RATING,
SUM(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN F.TOTAL_AMOUNT
	END
	) AS POST_CRISIS_TOTAL,
COUNT(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN F.ORDER_ID
	END
	) AS POST_CRISIS_ORDERS,
AVG(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN R.RATING
	END
	) AS POST_CRISIS_RATING
	FROM
	FACT_ORDER F
	 JOIN dim_customer c ON F.customer_id = c.customer_id
		  LEFT JOIN FACT_RATINGS R ON R.ORDER_ID=f.ORDER_ID
		  WHERE F.IS_CANCELLED='N'
		  GROUP BY c.customer_id,C.CITY
		)

		SELECT CUSTOMER_ID,CITY,ROUND(PRE_CRISIS_RATING,2) AS PRE_RATING,ROUND(POST_CRISIS_RATING,2) AS POST_RATING,
		ROUND(100* (pRE_CRISIS_TOTAL-POSt_CRISIS_TOTAL)::NUMERIC/NULLIF(PRE_CRISIS_TOTAL,0)::NUMERIC,2)  AS TOTAL_LOSS ,
		ROUND(100* (PRE_CRISIS_ORDERS-CTE.POST_CRISIS_ORDERS)::NUMERIC/NULLIF(PRE_CRISIS_ORDERS,0)::NUMERIC,2)
		AS ORDER_DECLINE_PERCENTANGE FROM CTE 
		WHERE PRE_CRISIS_TOTAL>=
		(SELECT PERCENTILE_CONT(.95) WITHIN GROUP(ORDER BY PRE_CRISIS_TOTAL) FROM cte)
		
		;		






=======
SELECT
	*
FROM
	DIM_CUSTOMER;

SELECT
	*
FROM
	DIM_DELIVERY_PARTNER;

SELECT
	*
FROM
	dim_restaurant;

SELECT
	*
FROM
	FACT_ORDER where ;

--Q1 Monthly Orders: Compare total orders across pre-crisis (Jan–May 2025) vs crisis
--(Jun–Sep 2025). How severe is the decline?
WITH
	CTE AS (
		SELECT
			COUNT(
				CASE
					WHEN DATE (ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN ORDER_ID
				END
			) AS PRE_CRISIS,
			COUNT(
				CASE
					WHEN DATE (ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN ORDER_ID
				END
			) AS POST_CRISIS
		FROM
			FACT_ORDER
	)
SELECT
	PRE_CRISIS,
	POST_CRISIS,
	ROUND(
		100 * (PRE_CRISIS - POST_CRISIS) / PRE_CRISIS::NUMERIC,
		2
	) AS DECLINE_PERCENTAGE
FROM
	CTE;

--Q2. Which top 5 city groups experienced the highest percentage decline in orders
--during the crisis period compared to the pre-crisis period?
WITH
	CTE AS (
		SELECT
			C.CITY AS CITY,
			COUNT(
				CASE
					WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN F.ORDER_ID
				END
			) AS PRE_CRISIS,
			COUNT(
				CASE
					WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN F.ORDER_ID
				END
			) AS POST_CRISIS
		FROM
			FACT_ORDER F
			INNER JOIN DIM_CUSTOMER C ON F.CUSTOMER_ID = C.CUSTOMER_ID
		GROUP BY
			CITY
	)
SELECT
	CITY,
	PRE_CRISIS,
	POST_CRISIS,
	ROUND(
		(PRE_CRISIS - POST_CRISIS) / PRE_CRISIS::NUMERIC * 100,
		2
	) AS DECLINE_PERCENTAGE
FROM
	CTE
ORDER BY
	DECLINE_PERCENTAGE DESC
LIMIT
	5;

--Q3 Among restaurants with at least 50 pre-crisis orders, which top 10 high-volume
--restaurants experienced the largest percentage decline in order counts during
--the crisis period?

 
WITH
CTE AS (
SELECT
r.restaurant_name as restaurant ,
COUNT(
CASE
WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN F.ORDER_ID
	END
) AS PRE_CRISIS,
COUNT(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN F.ORDER_ID
	END
	) AS POST_CRISIS
	FROM
	FACT_ORDER F
	 JOIN dim_restaurant r ON F.restaurant_id = r.restaurant_id
	 	GROUP BY r.restaurant_name 
			)

select   restaurant, pre_crisis, post_crisis,ROUND(
		(PRE_CRISIS - POST_CRISIS) / PRE_CRISIS::NUMERIC * 100,
		2
	) AS DECLINE_PERCENTAGE from cte where pre_crisis>=50 order by decline_percentage desc limit 10;

--Q4 Cancellation Analysis: What is the cancellation rate trend pre-crisis vs crisis,
--and which cities are most affected
	with cte as(
	SELECT
	r.city,
	COUNT(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN F.ORDER_ID
		END
	) AS PRE_CRISIS,
	COUNT(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'
	and F.is_cancelled='Y' THEN F.ORDER_ID
		END
	) AS PRE_CRISIS_CANCELLED,
	COUNT(
		CASE
		WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN F.ORDER_ID
		END
		) AS POST_CRISIS,
		COUNT(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP)  BETWEEN '2025-06-01' AND '2025-09-30' 
	and F.is_cancelled='Y' THEN F.ORDER_ID
		END
	) AS POST_CRISIS_CANCELLED
		FROM
		FACT_ORDER F  JOIN dim_restaurant r on r.restaurant_id=F.restaurant_id 
		group by r.city),
	cancellation_rates as(
	select city,round(PRE_CRISIS_CANCELLED/PRE_CRISIS::decimal*100,2) as pre_crisis_rate,
	round(POST_CRISIS_CANCELLED/POST_CRISIS::decimal*100 , 2) as
	post_crisis_rate from cte
		)
	select city,pre_crisis_rate,post_crisis_rate,post_crisis_rate - pre_crisis_rate as rate_change  
	from cancellation_rates order by rate_change desc
	 limit 10;

/*5. Delivery SLA: Measure average delivery time across phases. Did SLA
compliance worsen significantly in the crisis period?*/
--
with cte as(
select case
when date(o.order_timestamp) between '2025-06-01' AND '2025-09-30' then 'post_crisis'
else 'pre_crisis' end as time_period,
count(*) as total_orders,
round(avg(p.actual_delivery_time_mins),2) as avg_actual_delivery,
round(avg(p.expected_delivery_time_mins),2) as avg_expected_delivery,
sum(case when p.actual_delivery_time_mins<=p.expected_delivery_time_mins then 1 else 0 end)
as sla_compliant_orders
from 
fact_delivery_performance p join fact_order o on p.order_id=o.order_id
group by time_period order by time_period desc)

select time_period,avg_actual_delivery,avg_expected_delivery,
round(sla_compliant_orders/total_orders::decimal*100,2) as compliant_percentage from cte;


/*6. Ratings Fluctuation: Track average customer rating month-by-month. Which
months saw the sharpest drop?*/

 select to_char( review_timestamp,'Month') as months ,extract('month' from review_timestamp) as month_num,
 round(avg(rating),2) from fact_ratings group by months ,month_num
 order by month_num asc;

/*7. Sentiment Insights: During the crisis period, identify the most frequently
occurring negative keywords in customer review texts. (Hint: Use a Word Cloud
visual in Power BI to visualize the find*/

 SELECT unnest(ARRAY[
        'late', 'delay', 'cold', 'slow', 'bad', 'wrong','safety','small'
        'rude', 'missing', 'poor', 'unacceptable','average','less','issue','stale',
		'not','worst','terrible','horrible','okay'
    ]) AS word;

SELECT (review_text),count(review_text) as occurence
FROM fact_ratings
WHERE review_timestamp BETWEEN '2025-06-01' AND '2025-09-30'
group by review_text order by occurence desc ;


/*8.Revenue Impact: Estimate revenue loss from pre-crisis vs crisis (based on
subtotal, discount, and delivery fee).*/



with cte as(
select sum(case
when date(o.order_timestamp) between '2025-06-01' AND '2025-09-30' 
then i.line_total+o.delivery_fee end) as post_crisis_revenue,
sum(case
when date(o.order_timestamp) between '2025-01-01' AND '2025-05-31' 
then i.line_total+o.delivery_fee end) as pre_crisis_revenue
from fact_order o
join fact_order_items i on i.order_id=o.order_id
)

select pre_crisis_revenue,post_crisis_revenue,round(
(pre_crisis_revenue-post_crisis_revenue)/pre_crisis_revenue *100) as loss_percentage
from cte;


/*9. Loyalty Impact: Among customers who placed five or more orders before the
crisis, determine how many stopped ordering during the crisis, and out of those,
how many had an average rating above 4.5?*/


WITH
CTE AS (
SELECT
c.customer_id ,
COUNT(
CASE
WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN F.ORDER_ID
	END
) AS PRE_CRISIS,
COUNT(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN F.ORDER_ID
	END
	) AS POST_CRISIS
	FROM
	FACT_ORDER F
	 JOIN dim_customer c ON F.customer_id = c.customer_id
		 GROUP BY c.customer_id
	 order by pre_crisis desc
	)

	--select count(*) from cte where pre_crisis>=5 and post_crisis=0 --49 customers who stopped ordering
	
select r.customer_id as lost_customers,round( avg(r.rating),4) as avg_rating
	from cte join fact_ratings r on cte.customer_id=r.customer_id
	where pre_crisis>=5 and post_crisis=0 
	group by r.customer_id having avg(r.rating)>=4.5
	order by avg_rating desc
	;--30 out of 49 has 4.5+ rating



/*10. Customer Lifetime Decline: Which high-value customers (top 5% by total
spend before the crisis) showed the largest drop in order frequency and ratings
during the crisis? What common patterns (e.g., location, cuisine preference,
delivery delays) do they share?*/


WITH
CTE AS (
SELECT
c.customer_id ,C.CITY,ROUND(AVG(R.RATING),2) AS RATING,
SUM(
CASE
WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN F.TOTAL_AMOUNT
	END
) AS PRE_CRISIS_TOTAL,
COUNT(
CASE
WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN F.ORDER_ID
	END
) AS PRE_CRISIS_ORDERS,
AVG(
CASE
WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-01-01' AND '2025-05-31'  THEN R.RATING
	END
) AS PRE_CRISIS_RATING,
SUM(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN F.TOTAL_AMOUNT
	END
	) AS POST_CRISIS_TOTAL,
COUNT(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN F.ORDER_ID
	END
	) AS POST_CRISIS_ORDERS,
AVG(
	CASE
	WHEN DATE (F.ORDER_TIMESTAMP) BETWEEN '2025-06-01' AND '2025-09-30'  THEN R.RATING
	END
	) AS POST_CRISIS_RATING
	FROM
	FACT_ORDER F
	 JOIN dim_customer c ON F.customer_id = c.customer_id
		  LEFT JOIN FACT_RATINGS R ON R.ORDER_ID=f.ORDER_ID
		  WHERE F.IS_CANCELLED='N'
		  GROUP BY c.customer_id,C.CITY
		)

		SELECT CUSTOMER_ID,CITY,ROUND(PRE_CRISIS_RATING,2) AS PRE_RATING,ROUND(POST_CRISIS_RATING,2) AS POST_RATING,
		ROUND(100* (pRE_CRISIS_TOTAL-POSt_CRISIS_TOTAL)::NUMERIC/NULLIF(PRE_CRISIS_TOTAL,0)::NUMERIC,2)  AS TOTAL_LOSS ,
		ROUND(100* (PRE_CRISIS_ORDERS-CTE.POST_CRISIS_ORDERS)::NUMERIC/NULLIF(PRE_CRISIS_ORDERS,0)::NUMERIC,2)
		AS ORDER_DECLINE_PERCENTANGE FROM CTE 
		WHERE PRE_CRISIS_TOTAL>=
		(SELECT PERCENTILE_CONT(.95) WITHIN GROUP(ORDER BY PRE_CRISIS_TOTAL) FROM cte)
		
		;		






>>>>>>> b1ea29bbdcfac95373899e08947112e6059ddcba
