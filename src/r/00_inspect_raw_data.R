# Inspect the raw, pre-SQL datasets to understand their structure

library(dplyr)

cat("======================================================\n")
cat(" 1. INSPECTING RAW TELCO DATA (Internal)\n")
cat("======================================================\n")
# Read the raw telco flat file
raw_telco <- read.csv("data/raw/telco_churn.csv")

# Print the dimensions (Rows and Columns)
cat(sprintf("Total Rows: %d | Total Columns: %d\n\n", nrow(raw_telco), ncol(raw_telco)))

# Print a clean summary of the columns and the first few entries
glimpse(raw_telco)


cat("\n======================================================\n")
cat(" 2. INSPECTING RAW FRED CPI DATA (External API)\n")
cat("======================================================\n")
# Read the raw FRED flat file
raw_fred <- read.csv("data/raw/fred_cpi_data.csv")

cat(sprintf("Total Rows: %d | Total Columns: %d\n\n", nrow(raw_fred), ncol(raw_fred)))

# Print the first 10 rows to see the timeline
head(raw_fred, 10)