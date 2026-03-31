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




-- 3. Create the Master ML View (Integrating FRED Macro-Economic Data)

-- Demolish the old view to avoid column-order conflicts
DROP VIEW IF EXISTS v_customer_intelligence;

CREATE OR REPLACE VIEW v_customer_intelligence AS
WITH clean_data AS (
    SELECT 
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
        CAST(COALESCE(NULLIF(TRIM(CAST("TotalCharges" AS TEXT)), ''), '0') AS NUMERIC) AS total_charges,
        "Churn" AS churn
    FROM raw_telco_churn
),
date_engineered AS (
    -- Anchor to Jan 1, 2024. Subtract tenure (months) to find their exact signup month.
    SELECT 
        *,
        DATE_TRUNC('month', DATE '2024-01-01' - (tenure * INTERVAL '1 month'))::DATE AS estimated_signup_date
    FROM clean_data
),
feature_engineering AS (
    SELECT 
        d.*,
-- Internal Financial Engineering (Window Functions)
        AVG(CAST(monthly_charges AS NUMERIC)) OVER(PARTITION BY contract) AS avg_contract_monthly,
        CAST(monthly_charges AS NUMERIC) - AVG(CAST(monthly_charges AS NUMERIC)) OVER(PARTITION BY contract) AS charge_diff_from_avg,        
        -- External Macro-Economic Engineering (FRED API)
        CAST(f.cpi_value AS NUMERIC) AS cpi_at_signup,
        -- Calculate "Inflation Shock": CPI today (approx 308.4 for Jan 2024) minus CPI when they signed up
        (308.417 - CAST(f.cpi_value AS NUMERIC)) AS inflation_point_increase

    FROM date_engineered d
    LEFT JOIN raw_fred_cpi f ON d.estimated_signup_date = CAST(f.observation_date AS DATE)
)
SELECT 
    -- We select everything EXCEPT the raw dates, so the ML model only sees clean math
    customer_id, gender, senior_citizen, partner, dependents, tenure,
    phone_service, multiple_lines, internet_service, online_security,
    online_backup, device_protection, tech_support, streaming_tv,
    streaming_movies, contract, paperless_billing, payment_method,
    monthly_charges, total_charges, 
    avg_contract_monthly, charge_diff_from_avg, 
    cpi_at_signup, inflation_point_increase, 
    churn
FROM feature_engineering;


SELECT * FROM v_customer_intelligence LIMIT 100;