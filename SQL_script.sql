
-- Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

SELECT 
	cp.industry_branch_code,
	cp2.payroll_year AS previous_year,
	cp.payroll_year AS 'year',	
	round( avg( cp2.value), 2)  AS avg_payroll_prev_year,
	round( avg( cp.value), 2)  AS avg_payroll,	
	round( avg( cp.value) - avg( cp2.value)) AS payroll_growth,
	CASE WHEN round( avg( cp.value), 2) > round( avg( cp2.value), 2) THEN 'yes'
	ELSE '' END AS 'growing'
FROM czechia_payroll cp 
JOIN czechia_payroll cp2 
	ON cp.industry_branch_code = cp2.industry_branch_code  
	AND cp.payroll_year = cp2.payroll_year + 1
WHERE cp.value_type_code = 5958 AND cp.industry_branch_code  IS NOT NULL
GROUP BY cp.industry_branch_code, cp.payroll_year
;