-- JULIE MERDOVA

/* 5. Má výška HDP vliv na změny ve mzdách a cenách potravin? 
 * Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?
 */

WITH gdp AS (
			SELECT	tjmsf.YEAR, 
				country,
				GDP,
				LAG (GDP) OVER (ORDER BY tjmsf.YEAR) AS prev_GDP
			FROM t_julie_merdova_project_sql_secondary_final tjmsf 
			WHERE 	country = 'Czech Republic' 
				AND YEAR >=2006
			),
	growth_prices AS(
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
		GROUP BY payroll_year
					)
 	SELECT	growth_prices.actual_yr,
 		round(avg((GDP - prev_GDP)/prev_GDP)*100, 4) AS GDP_growth_AVG_perc,
		round(avg((avg_price - prev_avg_price)/prev_avg_price)*100, 4) AS price_growth_AVG_perc,
		round(avg((average_wage - prev_wage)/prev_wage)*100, 4) AS payroll_growth_AVG_perc
	FROM growth_prices
	JOIN payroll_grow 
		ON growth_prices.actual_yr = payroll_grow.payroll_year
	JOIN gdp 
		ON gdp.YEAR = payroll_grow.payroll_year
	WHERE growth_prices.actual_yr > 2006
	GROUP BY growth_prices.actual_yr
	;
