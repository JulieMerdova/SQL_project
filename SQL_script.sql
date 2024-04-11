
-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
SELECT 
	cp.industry_branch_code,
	cp2.payroll_year AS previous_year,
	cp.payroll_year AS 'year',	
	round( avg( cp2.value), 2)  AS avg_payroll_prev_year,
	round( avg( cp.value), 2)  AS avg_payroll,	
	round( (avg( cp.value) - avg( cp2.value))/avg( cp2.value),2) AS payroll_growth_perc,
	CASE WHEN round( avg( cp.value), 2) > round( avg( cp2.value), 2) THEN 'yes'
	ELSE '' END AS 'growing'
FROM czechia_payroll cp 
JOIN czechia_payroll cp2 
	ON cp.industry_branch_code = cp2.industry_branch_code  
	AND cp.payroll_year = cp2.payroll_year + 1
	AND cp.value_type_code = cp2.value_type_code 
	WHERE cp.value_type_code = 5958 AND cp.industry_branch_code  IS NOT NULL
GROUP BY cp.industry_branch_code, cp.payroll_year, cp2.payroll_year 
;
SELECT*
FROM czechia_payroll cp
WHERE cp.value_type_code =5958;

-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

-- pro Q1/2016 jsou prům. ceny chleba a mléka nasledující:
SELECT 
	category_code,
	year(date_from) AS 'year',
	quarter(date_from) AS 'quarter',
	round( avg( cp.value), 2) AS avg_price
FROM czechia_price cp 
WHERE 
	category_code IN ( '111301', '114201')
	AND year(date_from) = 2006
	AND quarter(date_from) = 1
GROUP BY 
	category_code,
	YEAR (date_from),
	quarter(date_from)
;
-- pro Q3/2018 jsou prům. ceny chleba a mléka nasledující:
SELECT 
	category_code,
	year(date_from) AS 'year',
	quarter(date_from) AS 'quarter',
	round( avg( cp.value), 2) AS avg_price
FROM czechia_price cp 
WHERE 
	category_code IN ( '111301', '114201')
	AND year(date_from) = 2018
	AND quarter(date_from) = 3
GROUP BY 
	category_code,
	YEAR (date_from),
	quarter(date_from)
;

-- srovnatelná období použijeme 1.Q/2006, kdy stál kilogram chleba 14,74 Kč a litr mléka 14,24 Kč 
-- a poslední bude 4.Q/2018, kdy stál kilogram chleba 24,06 Kč a litr mléka 20,16 Kč

SELECT 
	payroll_year,
	payroll_quarter ,
	round( avg (value), 0) AS 'avg_payroll_Q1/2006',
	round( (avg (value)/14.74), 0) 'amount_bread_kg',
	round( (avg (value)/14.24), 0) AS 'amount_milk_liter'
FROM czechia_payroll cp 
WHERE value_type_code = 5958 
AND industry_branch_code IS NOT NULL
AND payroll_year = 2006
AND payroll_quarter = 1
GROUP BY payroll_year , payroll_quarter 
;
-- v Q1/2006 si za průměrnou mzdu 19633 Kč můžeme koupit 1332 kg chleba a 1379 litrů mléka

SELECT 
	payroll_year,
	payroll_quarter ,
	round( avg (value), 0) AS 'avg_payroll_Q4/2018',
	round( (avg (value)/24.06), 0) 'amount_bread_kg',
	round( (avg (value)/20.16), 0) AS 'amount_milk_liter'
FROM czechia_payroll cp 
WHERE value_type_code = 5958 
AND industry_branch_code IS NOT NULL
AND payroll_year = 2018
AND payroll_quarter = 3
;

-- v Q4/2018 si za průměrnou mzdu 31 921 Kč můžeme koupit 1 327 kg chleba a 1 583 litrů mléka.

-- 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
