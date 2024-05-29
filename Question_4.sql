-- JULIE MERDOVA

-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

WITH growth_prices AS (
		SELECT	food_category,
			actual_yr,
			avg_price,
			LAG(avg_price) OVER (PARTITION BY food_category ORDER BY actual_yr) AS prev_avg_price
		FROM t_julie_merdova_project_sql_primary_final tjm
				),
	payroll_grow AS (
		SELECT	payroll_year,
			average_wage ,
			LAG(average_wage) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year) AS prev_wage
		FROM t_julie_merdova_project_sql_primary_final tjm
		GROUP BY payroll_year)
 	SELECT	growth_prices.actual_yr,
		round(avg((avg_price - prev_avg_price)/prev_avg_price)*100, 4) AS price_growth_AVG_perc,
		round(avg((average_wage - prev_wage)/prev_wage)*100, 4) AS payroll_growth_AVG_perc
	FROM growth_prices
	JOIN payroll_grow ON growth_prices.actual_yr = payroll_grow.payroll_year
	WHERE growth_prices.actual_yr > 2006
	GROUP BY growth_prices.actual_yr
	ORDER BY price_growth_AVG_perc DESC
	;
