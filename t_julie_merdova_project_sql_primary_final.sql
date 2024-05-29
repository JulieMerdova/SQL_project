-- JULIE MERDOVA

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

SELECT * 
FROM t_julie_merdova_project_sql_primary_final tjm
;