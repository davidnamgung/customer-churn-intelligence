# End-to-End Customer Retention and Churn Intelligence 🛡️
### Predicting Telecommunications Attrition via Multi-Source Data Pipelines

Full Link to report: [Report](https://davidnamgung.github.io/customer-churn-intelligence)

![Project Banner](https://img.shields.io/badge/Status-Complete-success)
![R](https://img.shields.io/badge/Language-R%20v4.3%2B-blue)
![DB](https://img.shields.io/badge/Database-PostgreSQL-orange)
![ML](https://img.shields.io/badge/Model-GBM%20(Gradient%20Boosting)-red)

## 1. 🎯 The Business Problem
Customer acquisition in the telecommunications sector is **5x to 25x more expensive** than retention. Currently, the company suffers from unpredicted churn, leading to significant monthly revenue leakage. This project addresses the "reactive" nature of current retention efforts by providing a proactive, data-driven flagging system.

### Core Objectives:
* **Predictive Risk Scoring:** Flag high-probability churners before they cancel.
* **Macro-Context Integration:** Join internal billing data with live economic indicators via the **Alpha Vantage API**.
* **Driver Discovery:** Move beyond "what" happened to "why" it happened using statistical inference ($Chi-Square$ & $T-Tests$).

---

## 2. 🏗️ Technical Architecture & ETL Pipeline
This project avoids "flat-file" analysis by simulating a production environment. The repository is split into dedicated `sql/` and `r/` environments to ensure a clean separation of concerns, with heavy computation pushed to the database layer.

### Phase 1: Database Initialization & Data Ingestion
* **`sql/01_create_database.sql`**: Initializes the local PostgreSQL `churn_db` environment.
* **`r/01_fetch_fred_data.R`**: Securely queries the FRED API for macroeconomic inflation indicators (CPI) using robust HTTP request handling (`httr2`), complete with automatic error retries, and parses the JSON response.
* **`r/02_load_data_to_sql.R`**: Bridges the file system and database by staging the raw Telco CSV and the downloaded FRED API data into PostgreSQL tables using the `DBI` and `RPostgres` drivers.

### Phase 2: In-Database Feature Engineering
* **`sql/02_investigation_and_engineering.sql`**: The core ETL script. It cleans dirty data (handling hidden NULLs in total charges), sanitizes columns to snake_case, and utilizes **SQL Window Functions** to engineer advanced financial metrics. For example, it calculates a customer's spend deviation from the average for their specific contract type to measure price sensitivity. It outputs a clean, unified view (`v_customer_intelligence`).

### Phase 3: Statistical Analysis & Modeling
* **`r/03_eda_and_inference.R`**: Extracts the clean SQL view into R memory, conducts statistical hypothesis testing to validate churn drivers (e.g., proving a statistically significant difference in monthly bills between churned and retained users), and automatically generates publication-ready `ggplot2` visualizations.
* **`r/04_predictive_modeling.R`**: The machine learning engine. Executes a 10-fold cross-validated "Algorithm Bake-Off" (Logistic Regression vs. Random Forest vs. GBM), evaluates the champion model on a 30% holdout test set, and outputs advanced visual diagnostics (ROC-AUC, Feature Importance).
---

## 3. 📊 Key Insights & Model Performance

### The "Churn Driver" Discovery
Through Feature Importance analysis, we discovered that **Contract Type** and **Monthly Charges** are the primary predictors. Customers on Month-to-Month plans with high electronic check payments represent the highest risk segment.

![Feature Importance](visualizations/09_feature_importance.png)

### Model Performance (The "Final Exam")
After a competitive "Bake-Off" between Logistic Regression, Random Forest, and GBM, the **GBM (Gradient Boosting Machine)** model was selected as the champion due to its superior AUC stability.

* **Overall Accuracy:** ~80%
* **ROC-AUC Score:** [Insert your AUC here, e.g., 0.84]
* **Business Impact:** At a 70% Recall rate, the business can capture the majority of potential "Leavers" for targeted retention campaigns.

![Confusion Matrix](visualizations/08_confusion_matrix.png)
![ROC Curve](visualizations/10_roc_auc_curve.png)

---

## 5. 🛠️ Engineering Challenges & Pivots
### The XGBoost Memory Conflict
During the ML phase, the pipeline encountered a deep-level C++ memory pointer conflict with the `xgboost` library (ALTREP error). 
**The Strategic Pivot:** Rather than stalling the project, I executed a pivot to **GBM (Gradient Boosting)**. This maintained the high predictive power of ensemble learning while ensuring 100% environment stability and native R compatibility.

---

## 6. ⚙️ How to Run
1.  **Clone the Repo:** ```bash
    git clone [https://github.com/davidnamgung/customer-churn-intelligence](https://github.com/davidnamgung/customer-churn-intelligence)
    ```
2.  **Environment Setup:** Ensure PostgreSQL is running locally and R libraries (`caret`, `gbm`, `pROC`, `tidyverse`, `httr2`, `RPostgres`) are installed. Create a `.Renviron` file in the root directory with `DB_PASSWORD=your_password` and `FRED_API_KEY=your_key`.
3.  **Execute Pipeline:** Run the scripts in the following chronological order:
    * Run `sql/01_create_database.sql`
    * Run `r/01_fetch_fred_data.R` then `r/02_load_data_to_sql.R`
    * Run `sql/02_investigation_and_engineering.sql`
    * Run `r/03_eda_and_inference.R` followed by `r/04_predictive_modeling.R`

---

## 6. 🚀 Future Roadmap
* **SMOTE Resampling:** Address class imbalance to further boost minority class recall.
* **Shiny Deployment:** Build a web-based dashboard for marketing managers to upload customer lists for real-time scoring.
* **Hyperparameter Tuning:** Implement a Random Search grid to optimize GBM learning rates.

---

## 👨‍💻 Porfolio Website
**David Namgung** [Portfolio](https://davidnamgung.github.io/portfolio-website/) 