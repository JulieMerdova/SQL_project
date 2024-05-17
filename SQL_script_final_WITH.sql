CREATE OR REPLACE TABLE t_julie_merdova_project_sql_primary_final AS
SELECT 	cp.industry_branch_code,
		cp.payroll_year AS payroll_year,
		round ( avg (cp.value), 0 ) AS average_wage,	
		cpc.name AS food_category,
		cpr.category_code AS category_code,
		round( avg( cpr.value), 2 )  AS avg_price,
		YEAR ( cpr.date_from ) AS actual_yr
FROM czechia_payroll cp
JOIN czechia_price cpr
	ON YEAR (cpr.date_from) = cp.payroll_year
	AND cp.industry_branch_code  IS NOT NULL
	AND cp.value_type_code = 5958
	AND cpr.region_code IS NULL
	AND cp.calculation_code = 200
JOIN czechia_price_category cpc
    ON cpr.category_code = cpc.code
GROUP BY industry_branch_code, 
		payroll_year, 
		food_category,
		category_code, 
		actual_yr
;

CREATE OR REPLACE TABLE t_julie_merdova_project_sql_secondary_final AS
SELECT 
	c.country,
	c.abbreviation,
	c.capital_city,
	c.currency_name ,
	c.currency_code,
	c.religion,
	c.government_type,
	e.YEAR,
	e.gdp,
	c.population 
FROM countries c
JOIN economies e 
	ON e.country = c.country 
WHERE continent LIKE 'europe' and GDP IS NOT null
ORDER BY c.country, e.`year` 
;


EXPLAIN SELECT * FROM v_tjm_prices_sql_project ;

SELECT *
FROM t_julie_merdova_project_sql_primary_final tjm
;

SELECT *
FROM t_julie_merdova_project_sql_secondary_final tjmsf 
;

-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

WITH wage_grow AS (
	SELECT industry_branch_code,
			payroll_year,
			average_wage ,
			lag(average_wage) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year) AS prev_wage
	FROM t_julie_merdova_project_sql_primary_final tjm
	GROUP BY industry_branch_code,
			average_wage  
	)
	SELECT industry_branch_code,
			average_wage,
			prev_wage,
			payroll_year,
			(SELECT payroll_year - 1) AS prev_payroll_yr,
			avg((average_wage-prev_wage)/prev_wage)*100 AS avg_grow_perc
	FROM 	wage_grow
	WHERE payroll_year > 2006
	GROUP BY industry_branch_code, payroll_year
;

/* 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední 
srovnatelné období v dostupných datech cen a mezd?
*/

-- nejprve zjistíme počátek a konec dostupných měření pro mléko a chleba

SELECT food_category,
		min (actual_yr),
		max (actual_yr)
FROM t_julie_merdova_project_sql_primary_final tjm
WHERE 	category_code IN ( 111301, 114201)
GROUP BY food_category
;

-- pro naše účely budeme tedy srovnávat roky 2006 a 2018, nyní zjistíme průměrné ceny v těchto obdobích:

SELECT 
	payroll_year,
	food_category,
	actual_yr,
	avg_price ,
	average_wage ,
	round (average_wage/ avg_price, 0) AS avg_amount
FROM t_julie_merdova_project_sql_primary_final tjm  
WHERE 	payroll_year IN (2006, 2018) 
		AND category_code IN ( 111301, 114201)
		AND actual_yr IN (2006, 2018)
GROUP BY 	payroll_year, 
			food_category, 	
			actual_yr
;
-- v roce 2006 jsme si za průměrnou mzdu 14 818 Kč mohli koupit 919 kg chleba a 1026 litrů mléka.
-- V roce 2018 jsme si za průměrnou mzdu 25 467 Kč mohli koupit 1051 kg chleba a 1285 litrů mléka.

/* 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
 */

WITH growth_prices AS (
		SELECT 	food_category,
				avg_price,
				LAG(avg_price) OVER (PARTITION BY food_category ORDER BY actual_yr) AS prev_avg_price
		FROM t_julie_merdova_project_sql_primary_final tjm
		-- WHERE actual_yr > 2006
				)
	SELECT	food_category,
			ROUND(AVG((avg_price - prev_avg_price)/prev_avg_price),6)*100 AS price_growth_AVG
	FROM growth_prices
	WHERE prev_avg_price IS NOT NULL 
	GROUP BY food_category
	ORDER BY price_growth_AVG
;


		-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
WITH growth_prices AS (
		SELECT 	food_category,
				actual_yr,
				avg_price,
				LAG(avg_price) OVER (PARTITION BY food_category ORDER BY actual_yr) AS prev_avg_price
		FROM t_julie_merdova_project_sql_primary_final tjm
				),
	payroll_grow AS (
		SELECT 	payroll_year,
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

/* Má výška HDP vliv na změny ve mzdách a cenách potravin? 
 * Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?
 */

WITH gdp AS (
			SELECT 	tjmsf.year, 
					country,
					GDP,
					LAG (GDP) OVER (ORDER BY 	tjmsf.year) AS prev_GDP
			FROM t_julie_merdova_project_sql_secondary_final tjmsf 
			WHERE country = 'Czech Republic' AND YEAR >=2006
			),
	growth_prices AS (
			SELECT 	food_category,
				actual_yr,
				avg_price,
				LAG(avg_price) OVER (PARTITION BY food_category ORDER BY actual_yr) AS prev_avg_price
			FROM t_julie_merdova_project_sql_primary_final tjm
				),
	payroll_grow AS (
		SELECT 	payroll_year,
				average_wage ,
				LAG(average_wage) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year) AS prev_wage
		FROM t_julie_merdova_project_sql_primary_final tjm
		GROUP BY payroll_year)
 	SELECT	growth_prices.actual_yr,
 			round(avg((GDP - prev_GDP)/prev_GDP)*100, 4) AS GDP_growth_AVG_perc,
			round(avg((avg_price - prev_avg_price)/prev_avg_price)*100, 4) AS price_growth_AVG_perc,
			round(avg((average_wage - prev_wage)/prev_wage)*100, 4) AS payroll_growth_AVG_perc
	FROM growth_prices
	JOIN payroll_grow ON growth_prices.actual_yr = payroll_grow.payroll_year
	JOIN gdp ON gdp.year = payroll_grow.payroll_year
	WHERE growth_prices.actual_yr > 2006
	GROUP BY growth_prices.actual_yr
	;




