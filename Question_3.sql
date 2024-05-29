-- JULIE MERDOVA

/* 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
 */

WITH growth_prices AS (
		SELECT 	food_category,
			avg_price,
			LAG(avg_price) OVER (PARTITION BY food_category ORDER BY actual_yr) AS prev_avg_price
		FROM t_julie_merdova_project_sql_primary_final tjm
				)
	SELECT	food_category,
		ROUND(AVG((avg_price - prev_avg_price)/prev_avg_price),6)*100 AS price_growth_AVG
	FROM growth_prices
	WHERE prev_avg_price IS NOT NULL 
	GROUP BY food_category
	ORDER BY price_growth_AVG
;
