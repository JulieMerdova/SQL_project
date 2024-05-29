-- JULIE MERDOVA

-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

WITH wage_grow AS (
	SELECT	industry_branch_code,
			payroll_year,
			average_wage ,
			lag(average_wage) OVER (PARTITION BY industry_branch_code ORDER BY payroll_year) AS prev_wage
	FROM t_julie_merdova_project_sql_primary_final tjm
	GROUP BY industry_branch_code,
			average_wage  
	)
	SELECT	industry_branch_code,
			average_wage,
			prev_wage,
			payroll_year,
			(SELECT payroll_year - 1) AS prev_payroll_yr,
			avg((average_wage-prev_wage)/prev_wage)*100 AS avg_grow_perc
	FROM 	wage_grow
	WHERE payroll_year > 2006
	GROUP BY	industry_branch_code, 
				payroll_year
;