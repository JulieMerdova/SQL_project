-- JULIE MERDOVA

/* 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední 
srovnatelné období v dostupných datech cen a mezd?
*/

-- nejprve zjistíme počátek a konec dostupných měření pro mléko a chleba

SELECT 	food_category,
		min (actual_yr),
		max (actual_yr)
FROM t_julie_merdova_project_sql_primary_final tjm
WHERE	category_code IN ( 111301, 114201)
GROUP BY food_category
;

-- pro naše účely budeme tedy srovnávat roky 2006 a 2018, nyní zjistíme průměrné ceny v těchto obdobích:

SELECT	payroll_year,
		food_category,
		actual_yr,
		avg_price ,
		average_wage ,
		round (average_wage/ avg_price, 0) AS avg_amount
FROM t_julie_merdova_project_sql_primary_final tjm  
WHERE	payroll_year IN (2006, 2018) 
		AND category_code IN ( 111301, 114201)
		AND actual_yr IN (2006, 2018)
GROUP BY 	payroll_year, 
			food_category, 	
			actual_yr
;
-- v roce 2006 jsme si za průměrnou mzdu 14 818 Kč mohli koupit 919 kg chleba a 1026 litrů mléka.
-- V roce 2018 jsme si za průměrnou mzdu 25 467 Kč mohli koupit 1051 kg chleba a 1285 litrů mléka.