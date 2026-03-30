# The Multi-Source Revenue Protector: Predicting Telecommunications Churn

## 1. The Business Problem
Customer acquisition in the telecommunications sector is highly expensive, making customer retention a critical driver of profitability for thousands of companies. Currently, the company experiences unpredicted churn, resulting in significant monthly revenue leakage. Furthermore, it is unclear how much of this churn is driven by internal service factors versus external macroeconomic pressures (e.g., inflation or consumer sentiment).

## 2. Core Objectives
This project aims to build an end-to-end data pipeline and predictive machine learning system to:
* **Identify At-Risk Customers:** Develop a predictive model (using Logistic Regression and Random Forest) to accurately flag customers with a high probability of canceling their subscriptions.
* **Integrate Macroeconomic Context:** Engineer a multi-source dataset by joining internal customer billing history with live external economic indicators via the Alpha Vantage API.
* **Determine Churn Drivers:** Perform statistical inference and feature importance analysis to understand exactly *why* customers are leaving.
* **Empower Stakeholders:** Deliver an interactive Tableau dashboard that allows marketing managers to simulate targeted retention campaigns.

## 3. Expected ROI & Business Impact
By identifying high-risk customers before they cancel, the business can shift from a reactive to a proactive retention strategy. 
* **Cost Savings:** Retaining an existing customer is estimated to be 5x to 25x cheaper than acquiring a new one.
* **Revenue Preservation:** If the model successfully identifies 70% of potential churners (Recall) and the business offers a targeted 10% discount to retain them, the company can actively prevent revenue loss while optimizing the marketing budget, eliminating blanket discounts given to already-loyal customers.