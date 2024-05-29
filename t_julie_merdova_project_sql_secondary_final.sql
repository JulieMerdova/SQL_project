-- JULIE MERDOVA

CREATE OR REPLACE TABLE t_julie_merdova_project_sql_secondary_final AS
SELECT 	c.country,
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
WHERE	continent LIKE 'europe' 
	AND GDP IS NOT null
ORDER BY	c.country, 
		e.YEAR 
;

SELECT * 
FROM t_julie_merdova_project_sql_secondary_final tjmpssf 
;
