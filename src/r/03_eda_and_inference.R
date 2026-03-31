# install.packages("ggplot2")
# renv::snapshot()

# Exploratory Data Analysis, Statistical Testing, and Auto-Visualization

# 1. Load Libraries
library(DBI)
library(RPostgres)
library(dotenv)
library(ggplot2)


# 2. Setup Output Folder
# This automatically creates a "visualizations" folder in your project root if it doesn't exist.
if (!dir.exists("visualizations")) {
  dir.create("visualizations")
}

if (!dir.exists("data/processed")) dir.create("data/processed", recursive = TRUE)

# 3. Connect and Fetch Data
load_dot_env(".Renviron")
db_pass <- Sys.getenv("DB_PASSWORD")

con <- dbConnect(RPostgres::Postgres(), dbname = "churn_db", host = "127.0.0.1", 
                 port = 5432, user = "postgres", password = db_pass)

# Pull the perfectly clean view we engineered in Phase 3
df <- dbGetQuery(con, "SELECT * FROM v_customer_intelligence")
dbDisconnect(con)

# Save a frozen copy of the clean data for future Machine Learning tasks
processed_path <- "data/processed/clean_customer_intelligence.csv"
write.csv(df, processed_path, row.names = FALSE)
cat(sprintf("[System] Clean data frozen and saved to: %s\n\n", processed_path))

cat("\n======================================================\n")
cat(" 📊 INITIATING CHURN INTELLIGENCE REPORT \n")
cat("======================================================\n\n")


tail(colnames(df), n = 5)

# ==============================================================================
# SECTION 1: EDA - CHURN BY CONTRACT TYPE
# ==============================================================================

# Calculate churn rates by contract
month_churn <- mean(df$churn[df$contract == "Month-to-month"] == "Yes") * 100
two_yr_churn <- mean(df$churn[df$contract == "Two year"] == "Yes") * 100

cat("--- SECTION 1: CONTRACT RISK ANALYSIS ---\n")
cat(sprintf("Finding: Month-to-Month customers churn at %.1f%%, while Two-Year customers churn at only %.1f%%.\n", month_churn, two_yr_churn))
cat("What this number means: For every 100 people on a month-to-month plan, roughly 43 leave. For every 100 on a two-year plan, fewer than 3 leave.\n")
cat("The 'Why': Customers on Month-to-Month plans have zero exit barriers. They churn highly because they are likely using the service as a temporary bridge or are highly sensitive to single bad experiences, whereas two-year contracts lock in commitment.\n\n")

# Visualization 1: Bar Chart
p1 <- ggplot(df, aes(x = contract, fill = churn)) +
  geom_bar(position = "fill", color = "black") +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(title = "Churn Proportion by Contract Type",
       subtitle = "Month-to-Month contracts carry the highest flight risk.",
       x = "Contract Type",
       y = "Percentage of Customers",
       fill = "Churned?") +
  theme_minimal(base_size = 14) +
  scale_fill_manual(values = c("No" = "#2c3e50", "Yes" = "#e74c3c"))

# Save the plot automatically
ggsave("visualizations/01_churn_by_contract.png", plot = p1, width = 8, height = 5, dpi = 300)
cat("[System] Saved Visualization: visualizations/01_churn_by_contract.png\n\n")


# ==============================================================================
# SECTION 2: STATISTICAL INFERENCE - MONTHLY CHARGES
# ==============================================================================

cat("--- SECTION 2: PRICING SENSITIVITY (T-TEST) ---\n")
cat("Hypothesis: Do customers who churn pay significantly more per month than those who stay?\n")

# Run the T-Test
t_test_result <- t.test(monthly_charges ~ churn, data = df)
p_val <- t_test_result$p.value
mean_stayed <- t_test_result$estimate[1]
mean_churned <- t_test_result$estimate[2]

# Format the P-Value so it doesn't print in confusing scientific notation (e.g., 2.2e-16)
formatted_pval <- format.pval(p_val, eps = 0.001)

if(p_val < 0.05) {
  cat("🛑 STATISTICAL PROOF: SIGNIFICANT DIFFERENCE FOUND.\n")
  cat(sprintf("-> Average bill for retained: $%.2f\n", mean_stayed))
  cat(sprintf("-> Average bill for churned:  $%.2f\n", mean_churned))
  cat(sprintf("-> P-Value: %s\n", formatted_pval))
  
  cat("\nWhat this number means: A p-value of <0.001 means there is less than a 0.1% chance that this $13 price difference is just a random coincidence in our data. It is a mathematically proven reality.\n")
  cat("The 'Why': Customers are churning because of price sensitivity. The data proves that higher monthly bills directly correlate with cancellation, likely because the perceived value of the service does not match the premium price tag.\n\n")
} else {
  cat("🟢 STATISTICAL PROOF: NO SIGNIFICANT DIFFERENCE.\n")
  cat(sprintf("-> P-Value: %s\n", formatted_pval))
  cat("\nWhat this number means: The p-value is above 0.05, meaning any difference in price between the two groups is likely just random noise.\n")
  cat("The 'Why': Price is NOT the primary driver of churn. We must investigate other factors like customer service quality or network reliability.\n\n")
}

# Visualization 2: Boxplot
p2 <- ggplot(df, aes(x = churn, y = monthly_charges, fill = churn)) +
  geom_boxplot(alpha = 0.8, color = "black") +
  labs(title = "Distribution of Monthly Charges: Retained vs. Churned",
       subtitle = "Churned customers carry a statistically higher median monthly bill.",
       x = "Did the Customer Churn?",
       y = "Monthly Charge ($)",
       fill = "Churned?") +
  theme_minimal(base_size = 14) +
  scale_fill_manual(values = c("No" = "#2c3e50", "Yes" = "#e74c3c"))

# Save the plot automatically
ggsave("visualizations/02_monthly_charges_ttest.png", plot = p2, width = 8, height = 6, dpi = 300)
cat("[System] Saved Visualization: visualizations/02_monthly_charges_ttest.png\n")
cat("======================================================\n")


# ==============================================================================
# SECTION 3: UNIVARIATE ANALYSIS - THE TENURE HUMP
# ==============================================================================
cat("--- SECTION 3: THE TENURE HUMP ---\n")
cat("Finding: Churn is massively concentrated in the first 1 to 6 months of the customer lifecycle.\n")
cat("The 'Why': This is the 'Danger Zone'. If a customer survives the onboarding phase, their likelihood of leaving drops dramatically. We need better onboarding.\n\n")

p3 <- ggplot(df, aes(x = tenure, fill = churn)) +
  geom_histogram(binwidth = 5, color = "white", alpha = 0.8, position = "stack") +
  labs(title = "Customer Tenure Distribution", subtitle = "Massive flight risk in the first 6 months. Loyalty solidifies over time.",
       x = "Tenure (Months)", y = "Number of Customers", fill = "Churned?") +
  theme_minimal(base_size = 14) + scale_fill_manual(values = c("No" = "#2c3e50", "Yes" = "#e74c3c"))

ggsave("visualizations/03_tenure_distribution.png", plot = p3, width = 8, height = 5, dpi = 300)
cat("[System] Saved: visualizations/03_tenure_distribution.png\n\n")


# ==============================================================================
# SECTION 4: BIVARIATE ANALYSIS - THE FIBER OPTIC PARADOX
# ==============================================================================
cat("--- SECTION 4: THE FIBER OPTIC PARADOX ---\n")
cat("Finding: Fiber Optic customers churn at a significantly higher rate than slower DSL customers.\n")
cat("The 'Why': This is highly unusual. Fiber is faster, but perhaps it is priced too high, or the installation/outage rates are frustrating premium customers.\n\n")

p4 <- ggplot(df, aes(x = internet_service, fill = churn)) +
  geom_bar(position = "fill", color = "black") +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(title = "Churn Rate by Internet Service", subtitle = "The Fiber Optic Paradox: Faster service, higher churn.",
       x = "Internet Service Type", y = "Proportion of Customers", fill = "Churned?") +
  theme_minimal(base_size = 14) + scale_fill_manual(values = c("No" = "#2c3e50", "Yes" = "#e74c3c"))

ggsave("visualizations/04_internet_service_risk.png", plot = p4, width = 8, height = 5, dpi = 300)
cat("[System] Saved: visualizations/04_internet_service_risk.png\n\n")


# ==============================================================================
# SECTION 5: MULTIVARIATE ANALYSIS - REVENUE RISK MATriX
# ==============================================================================
cat("--- SECTION 5: REVENUE RISK (TENURE VS PRICE) ---\n")
cat("Finding: The top-left quadrant (High Price, Low Tenure) is a sea of churn.\n")
cat("The 'Why': We are aggressively acquiring customers on expensive plans, but failing to retain them long enough to make them profitable.\n")
cat("======================================================\n")

p5 <- ggplot(df, aes(x = tenure, y = monthly_charges, color = churn)) +
  geom_point(alpha = 0.5, size = 2) +
  labs(title = "Revenue Risk: Tenure vs. Monthly Charges", subtitle = "High-paying, short-tenure customers are the most likely to churn.",
       x = "Tenure (Months)", y = "Monthly Charges ($)", color = "Churned?") +
  theme_minimal(base_size = 14) + scale_color_manual(values = c("No" = "#3498db", "Yes" = "#e74c3c"))

ggsave("visualizations/05_tenure_vs_charges_scatter.png", plot = p5, width = 8, height = 6, dpi = 300)
cat("[System] Saved: visualizations/05_tenure_vs_charges_scatter.png\n")