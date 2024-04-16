CREATE OR REPLACE TABLE t_julie_merdova_project_sql_primary_final AS
SELECT 	cp.industry_branch_code,
		cp.payroll_year AS payroll_year,
		cp2.payroll_year AS previous_year,
		cp.payroll_quarter,
		cp.value AS average_wage,	
		cp2.value AS previous_average_wage,	
		cpc.name AS food_category,
		cpr.category_code,
		cpr.value AS price,
		cp.payroll_quarter AS 'quarter',
		cpr.date_from AS price_measured_from ,
    	cpr.date_to AS price_measured_to
FROM czechia_payroll cp
JOIN czechia_price cpr
	ON YEAR (cpr.date_from) = cp.payroll_year
	AND cpr.category_code IN ( '111301', '114201')
	AND cp.industry_branch_code  IS NOT NULL
	AND cp.value_type_code = 5958
	AND cpr.region_code IS NULL
	AND cp.value IS NOT NULL
JOIN czechia_price_category cpc
    ON cpr.category_code = cpc.code
JOIN czechia_payroll cp2
	ON cp.industry_branch_code = cp2.industry_branch_code  
	AND cp.payroll_year = cp2.payroll_year + 1
	AND cp.payroll_quarter = cp2.payroll_quarter
	AND cp.value_type_code = cp2.value_type_code
;
SELECT *
FROM t_julie_merdova_project_sql_primary_final tjm
;


-- '114201')

SELECT *
FROM czechia_price cp 
WHERE category_code IN ( '111301', '114201')
ORDER BY date_from 
;
-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?


SELECT  tjm.industry_branch_code,
		tjm.payroll_year,
		tjm.previous_year,	
		round( avg( tjm.previous_average_wage), 2)  AS avg_payroll_prev_year,
		round( avg( tjm.average_wage), 2)  AS avg_payroll,	
		round( (avg( tjm.average_wage) - avg( tjm.previous_average_wage))/avg( tjm.previous_average_wage),2) AS payroll_growth_perc,
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
		min (price_measured_from)
FROM t_julie_merdova_project_sql_primary_final tjm
WHERE category_code = '111301'
GROUP BY food_category
;

SELECT food_category,
		max (price_measured_to)
FROM t_julie_merdova_project_sql_primary_final tjm
WHERE category_code = '111301'
GROUP BY food_category

SELECT food_category,
		min (price_measured_from)
FROM t_julie_merdova_project_sql_primary_final tjm
WHERE category_code = '114201'
GROUP BY food_category
;

SELECT food_category,
		max (price_measured_to)
FROM t_julie_merdova_project_sql_primary_final tjm
WHERE category_code = '114201'
GROUP BY food_category

-- pro naše účely budeme srovnávat Q1/2006 a Q3/2018, nyní zjistíme průměrné ceny v těchto obdobích:

SELECT 
	category_code,
	year(price_measured_from) AS 'year',
	quarter(price_measured_from) AS 'quarter',
	round( avg( tjm.price), 2) AS avg_price
FROM t_julie_merdova_project_sql_primary_final tjm 
WHERE 
	category_code IN ( '111301', '114201')
	AND year(price_measured_from) = 2006
	AND quarter(price_measured_from) = 1
GROUP BY 
	category_code,
	YEAR (price_measured_from),
	quarter(price_measured_from)
;
-- pro Q3/2018 jsou prům. ceny chleba a mléka nasledující:
SELECT 
	category_code,
	year(price_measured_from) AS 'year',
	quarter(price_measured_from) AS 'quarter',
	round( avg( price), 2) AS avg_price
FROM t_julie_merdova_project_sql_primary_final tjm
WHERE 
	category_code IN ( '111301', '114201')
	AND year(price_measured_from) = 2018
	AND quarter(price_measured_from) = 3
GROUP BY 
	category_code,
	YEAR (price_measured_from),
	quarter(price_measured_from)
;

/* srovnatelná období použijeme 1.Q/2006, kdy stál kilogram chleba 14,74 Kč a litr mléka 14,24 Kč 
 a poslední bude 3.Q/2018, kdy stál kilogram chleba 24,06 Kč a litr mléka 20,16 Kč
*/

SELECT 
	payroll_year,
	payroll_quarter ,
	round( avg (average_wage), 0) AS 'avg_payroll_Q1/2006',
	round( (avg (average_wage)/14.74), 0) 'amount_bread_kg',
	round( (avg (average_wage)/14.24), 0) AS 'amount_milk_liter'
FROM t_julie_merdova_project_sql_primary_final tjm  
WHERE 	payroll_year = 2006
	AND payroll_quarter = 1
GROUP BY payroll_year , payroll_quarter 
;
-- v Q1/2006 si za průměrnou mzdu 19633 Kč můžeme koupit 1332 kg chleba a 1379 litrů mléka

SELECT 
	payroll_year,
	payroll_quarter ,
	round( avg (average_wage), 0) AS 'avg_payroll_Q4/2018',
	round( (avg (average_wage)/24.06), 0) 'amount_bread_kg',
	round( (avg (average_wage)/20.16), 0) AS 'amount_milk_liter'
FROM t_julie_merdova_project_sql_primary_final tjmpspf  
WHERE 	payroll_year = 2018
		AND payroll_quarter = 3
;

-- v Q4/2018 si za průměrnou mzdu 31 921 Kč můžeme koupit 1 327 kg chleba a 1 583 litrů mléka.