CREATE OR REPLACE TABLE t_julie_merdova_project_sql_primary_final AS
SELECT 	cp.industry_branch_code,
		cp.payroll_year AS payroll_year,
		cp2.payroll_year AS previous_year,
		round ( avg (cp.value), 0 ) AS average_wage,	
		round ( avg (cp2.value), 0 ) AS previous_average_wage,	
		cpc.name AS food_category,
		cpr.category_code AS category_code,
		round( avg( cpr.value), 2 )  AS avg_price,
		(SELECT ROUND(AVG(cpr2.value), 2) 
			FROM czechia_price cpr2 
			WHERE YEAR(cpr2.date_from) = YEAR(cpr.date_from) - 1 
			AND cpr2.category_code = cpr.category_code) AS avg_price_prev_year,
		YEAR ( cpr.date_from ) AS actual_yr,
    	YEAR ( cpr.date_from ) - 1 AS prev_yr
FROM czechia_payroll cp
JOIN czechia_price cpr
	ON YEAR (cpr.date_from) = cp.payroll_year
	AND cp.industry_branch_code  IS NOT NULL
	AND cp.value_type_code = 5958
	AND cpr.region_code IS NULL
	AND cp.calculation_code = 200
JOIN czechia_price_category cpc
    ON cpr.category_code = cpc.code
JOIN czechia_payroll cp2
	ON cp.industry_branch_code = cp2.industry_branch_code  
	AND cp.payroll_year = cp2.payroll_year + 1
	AND cp.payroll_quarter = cp2.payroll_quarter
	AND cp.calculation_code = cp2.calculation_code
	AND cp.value_type_code = cp2.value_type_code
GROUP BY industry_branch_code, 
		payroll_year, 
		previous_year, 
		food_category, 
		category_code, 
		YEAR ( cpr.date_from ),
		YEAR ( cpr.date_from ) - 1
;

EXPLAIN SELECT * FROM v_tjm_prices_sql_project ;

SELECT *
FROM t_julie_merdova_project_sql_primary_final tjm
;

-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?


SELECT  tjm.industry_branch_code,
		tjm.previous_year,	
		tjm.payroll_year,
		round( avg( tjm.previous_average_wage), 2)  AS avg_payroll_prev_year,
		round( avg( tjm.average_wage), 2)  AS avg_payroll,	
		round( (avg( tjm.average_wage) - avg( tjm.previous_average_wage))/avg( tjm.previous_average_wage),2) * 100 AS payroll_growth_perc,
	CASE WHEN round( avg( tjm.average_wage), 2) > round( avg( tjm.previous_average_wage), 2) THEN 'yes'
	ELSE '' END AS 'growing'
FROM t_julie_merdova_project_sql_primary_final tjm
GROUP BY tjm.industry_branch_code, tjm.payroll_year, tjm.previous_year
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

-- pro naše účely budeme tedy srovnávat roky 2016 a 2018, nyní zjistíme průměrné ceny v těchto obdobích:

SELECT 
	food_category,
	actual_yr,
	avg_price
FROM t_julie_merdova_project_sql_primary_final tjm 
WHERE 	category_code IN ( 111301, 114201)
		AND actual_yr IN (2006, 2018) 
GROUP BY 
	food_category,
	actual_yr
;

/* srovnatelná období použijeme roky 2006, kdy stál kilogram chleba 16,12 Kč a litr mléka 14,44 Kč 
 a poslední bude 2018, kdy stál průměrně kilogram chleba 24,24 Kč a litr mléka 19,82 Kč
*/

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
SELECT 	food_category ,
		actual_yr ,
		prev_yr ,
		avg_price_prev_year,
		avg_price,	
		round(( avg_price - avg_price_prev_year)/avg_price_prev_year,2) * 100 AS payroll_growth_perc
FROM t_julie_merdova_project_sql_primary_final tjm
WHERE actual_yr > 2006
GROUP BY 	food_category ,
			actual_yr ,
			prev_yr
;
