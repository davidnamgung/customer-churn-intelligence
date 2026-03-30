-- 1. Check for NULLs in critical columns
-- In the Telco dataset, 'TotalCharges' often has hidden empty strings.
-- Safe Check: converts to text first so Postgres doesn't crash comparing a number to a space
SELECT 
    COUNT(*) AS total_rows,
    COUNT("customerID") AS valid_ids,
    SUM(CASE WHEN TRIM(CAST("TotalCharges" AS TEXT)) = '' OR "TotalCharges" IS NULL THEN 1 ELSE 0 END) AS empty_total_charges
FROM raw_telco_churn;

-- 2. Check the distribution of Churn
-- This tells us if our classes are balanced (Spoiler: usually they aren't).
SELECT "Churn", COUNT(*) AS count, 
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM raw_telco_churn
GROUP BY "Churn";




-- 3. Create a VIEW so we can easily pull this into R/Tableau later
CREATE OR REPLACE VIEW v_customer_intelligence AS
WITH clean_data AS (
    SELECT 
        -- Renaming columns to snake_case so we NEVER need double quotes again
        "customerID" AS customer_id,
        "gender" AS gender,
        "SeniorCitizen" AS senior_citizen,
        "Partner" AS partner,
        "Dependents" AS dependents,
        "tenure" AS tenure,
        "PhoneService" AS phone_service,
        "MultipleLines" AS multiple_lines,
        "InternetService" AS internet_service,
        "OnlineSecurity" AS online_security,
        "OnlineBackup" AS online_backup,
        "DeviceProtection" AS device_protection,
        "TechSupport" AS tech_support,
        "StreamingTV" AS streaming_tv,
        "StreamingMovies" AS streaming_movies,
        "Contract" AS contract,
        "PaperlessBilling" AS paperless_billing,
        "PaymentMethod" AS payment_method,
        "MonthlyCharges" AS monthly_charges,
        
        -- Casts to text (avoids type crashes), trims spaces, turns empty to NULL, 
        -- defaults to '0', and safely casts to NUMERIC.
        CAST(COALESCE(NULLIF(TRIM(CAST("TotalCharges" AS TEXT)), ''), '0') AS NUMERIC) AS total_charges,
        
        "Churn" AS churn
    FROM raw_telco_churn
),
feature_engineering AS (
    SELECT 
        *,
        -- Window Functions for Advanced Features
        AVG(monthly_charges) OVER(PARTITION BY contract) AS avg_contract_monthly,
        monthly_charges - AVG(monthly_charges) OVER(PARTITION BY contract) AS charge_diff_from_avg,
        RANK() OVER(PARTITION BY contract ORDER BY total_charges DESC) AS spend_rank_in_contract
    FROM clean_data
)
SELECT * FROM feature_engineering;

-- Why use window functions? 
-- Window functions allow you to perform calculations across a set of table rows that are somehow related to the current row.
-- AVG("MonthlyCharges") OVER(PARTITION BY "Contract") calculates the average bill for everyone on a Month-to-Month plan, 
--      and attaches that value to every customer on that plan. This allows us to calculate a "Z-score" or deviation:
-- $$Deviation = \text{MonthlyCharges} - \mu_{\text{contract\_type}}$$

-- If a customer's deviation is high, they might be more likely to churn because they feel they are overpaying compared to their peers!




-- 4. Linking FRED CPI data 
-- Telco data doesn't have "Dates," only "Tenure." 
-- We will assume the data was pulled in 2025-01-01 (latest point) and "look back."

-- Join Churn Data with Inflation Data
-- This shows if high inflation months correlate with higher churn rates.
SELECT 
    t.*,
    c.cpi_value AS inflation_index
FROM v_customer_intelligence t
LEFT JOIN raw_fred_cpi c 
    ON c.observation_date = '2025-01-01' -- Placeholder join for current economic state
LIMIT 100;