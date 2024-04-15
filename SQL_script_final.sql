CREATE OR REPLACE TABLE t_julie_merdova_project_sql_primary_final AS
SELECT 	cp.value,
		cp.value_type_code,
		cp.industry_branch_code,
		cp.payroll_year
FROM czechia_payroll cp
;

SELECT *
FROM t_julie_merdova_project_sql_primary_final tjmpspf 
;

-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
SELECT 
	tj.industry_branch_code,
	tj2.payroll_year AS previous_year,
	tj.payroll_year AS 'year',	
	round( avg( tj2.value), 2)  AS avg_payroll_prev_year,
	round( avg( tj.value), 2)  AS avg_payroll,	
	round( (avg( tj.value) - avg( tj2.value))/avg( tj2.value),2) AS payroll_growth_perc,
	CASE WHEN round( avg( tj.value), 2) > round( avg( tj2.value), 2) THEN 'yes'
	ELSE '' END AS 'growing'
FROM t_julie_merdova_project_sql_primary_final tj 
JOIN t_julie_merdova_project_sql_primary_final tj2 
	ON tj.industry_branch_code = tj2.industry_branch_code  
	AND tj.payroll_year = tj2.payroll_year + 1
	AND tj.value_type_code = tj2.value_type_code 
	WHERE tj.value_type_code = 5958 AND tj.industry_branch_code  IS NOT NULL
GROUP BY tj.industry_branch_code, tj.payroll_year, tj2.payroll_year 
;