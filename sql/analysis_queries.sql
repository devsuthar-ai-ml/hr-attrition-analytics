-- HR attrition analysis (SQLite). Table: employees (1,470 rows, built by scripts/prepare_data.py)
-- attrition = 'Yes' means the employee left.

-- Q1. Headline KPIs
SELECT COUNT(*)                                             AS employees,
       SUM(attrition = 'Yes')                               AS attrition_count,
       ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 2)  AS attrition_rate_pct,
       SUM(attrition = 'No')                                AS active_employees,
       ROUND(AVG(age), 2)                                   AS avg_age
FROM employees;

-- Q2. Department: attrition COUNT vs attrition RATE
SELECT department,
       COUNT(*)                                            AS employees,
       SUM(attrition = 'Yes')                              AS left_count,
       ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1) AS attrition_rate_pct
FROM employees
GROUP BY department
ORDER BY attrition_rate_pct DESC;

-- Q3. Age band
SELECT CASE WHEN age < 25 THEN '1. Under 25'
            WHEN age < 35 THEN '2. 25-34'
            WHEN age < 45 THEN '3. 35-44'
            WHEN age < 55 THEN '4. 45-54'
            ELSE '5. 55+' END                              AS age_band,
       COUNT(*)                                            AS employees,
       SUM(attrition = 'Yes')                              AS left_count,
       ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1) AS attrition_rate_pct
FROM employees
GROUP BY age_band
ORDER BY age_band;

-- Q4. Overtime
SELECT over_time,
       COUNT(*)                                            AS employees,
       SUM(attrition = 'Yes')                              AS left_count,
       ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1) AS attrition_rate_pct
FROM employees
GROUP BY over_time
ORDER BY attrition_rate_pct DESC;

-- Q5. Job roles ranked by attrition rate (window function)
SELECT RANK() OVER (ORDER BY 1.0 * SUM(attrition = 'Yes') / COUNT(*) DESC) AS risk_rank,
       job_role,
       COUNT(*)                                            AS employees,
       SUM(attrition = 'Yes')                              AS left_count,
       ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1) AS attrition_rate_pct
FROM employees
GROUP BY job_role
ORDER BY risk_rank;

-- Q6. Tenure band (years at company)
SELECT CASE WHEN years_at_company <= 1  THEN '1. 0-1 yr'
            WHEN years_at_company <= 3  THEN '2. 2-3 yrs'
            WHEN years_at_company <= 5  THEN '3. 4-5 yrs'
            WHEN years_at_company <= 10 THEN '4. 6-10 yrs'
            ELSE '5. 10+ yrs' END                          AS tenure_band,
       COUNT(*)                                            AS employees,
       SUM(attrition = 'Yes')                              AS left_count,
       ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1) AS attrition_rate_pct
FROM employees
GROUP BY tenure_band
ORDER BY tenure_band;

-- Q7. Monthly income quartiles (NTILE)
WITH q AS (
    SELECT attrition, monthly_income,
           NTILE(4) OVER (ORDER BY monthly_income) AS income_quartile
    FROM employees
)
SELECT income_quartile,
       MIN(monthly_income)                                 AS min_income,
       MAX(monthly_income)                                 AS max_income,
       COUNT(*)                                            AS employees,
       SUM(attrition = 'Yes')                              AS left_count,
       ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1) AS attrition_rate_pct
FROM q
GROUP BY income_quartile
ORDER BY income_quartile;

-- Q8. Overtime x marital status (CTE)
WITH seg AS (
    SELECT over_time, marital_status,
           COUNT(*)               AS employees,
           SUM(attrition = 'Yes') AS left_count
    FROM employees
    GROUP BY over_time, marital_status
)
SELECT over_time, marital_status, employees, left_count,
       ROUND(100.0 * left_count / employees, 1) AS attrition_rate_pct
FROM seg
ORDER BY attrition_rate_pct DESC;

-- Q9. High-risk profile: under 35, single, works overtime
SELECT COUNT(*)                                            AS employees,
       SUM(attrition = 'Yes')                              AS left_count,
       ROUND(100.0 * SUM(attrition = 'Yes') / COUNT(*), 1) AS attrition_rate_pct
FROM employees
WHERE age < 35 AND marital_status = 'Single' AND over_time = 'Yes';

-- Q10. Satisfaction scores: leavers vs stayers
SELECT attrition,
       ROUND(AVG(job_satisfaction), 2)         AS avg_job_satisfaction,
       ROUND(AVG(environment_satisfaction), 2) AS avg_env_satisfaction,
       ROUND(AVG(work_life_balance), 2)        AS avg_work_life_balance,
       ROUND(AVG(monthly_income), 0)           AS avg_monthly_income,
       ROUND(AVG(years_at_company), 1)         AS avg_years_at_company
FROM employees
GROUP BY attrition;
