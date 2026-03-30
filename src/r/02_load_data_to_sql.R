# install.packages(c("DBI", "RPostgres", "readr"))
# renv::snapshot()

# Purpose: Loads raw CSV flat files into the PostgreSQL churn_db database


# 1. Load Libraries
library(DBI)       # Standard Database Interface for R
library(RPostgres) # Specific driver for PostgreSQL
library(readr)     # Fast CSV reader
library(dotenv)    # For hidden passwords

print("Initializing Database Connection...")

# 2. Load Hidden Environment Variables
load_dot_env(".Renviron")
db_pass <- Sys.getenv("DB_PASSWORD")

# 3. Connect to the Local PostgreSQL Database
# We are connecting specifically to the 'churn_db' we created in SQLTools
con <- dbConnect(
  RPostgres::Postgres(),
  dbname   = "churn_db",
  host     = "127.0.0.1", 
  port     = 5432,
  user     = "postgres",
  password = db_pass
)

print("Connection Successful! Reading flat files...")

# 4. Read the Raw CSV Files into R Memory
# Make sure your telco file is named exactly this in your data/raw folder
telco_data <- read_csv("data/raw/telco_churn.csv", show_col_types = FALSE)
cpi_data   <- read_csv("data/raw/fred_cpi_data.csv", show_col_types = FALSE)

print("Writing tables to PostgreSQL...")

# 5. Write Tables to the Database
# dbWriteTable automatically creates the SQL table structure based on the R dataframe!
# overwrite = TRUE ensures that if you run this script twice, it replaces the old table.

dbWriteTable(con, name = "raw_telco_churn", value = telco_data, overwrite = TRUE)
dbWriteTable(con, name = "raw_fred_cpi", value = cpi_data, overwrite = TRUE)

# 6. Close the Connection (Crucial for Data Hygiene!)
dbDisconnect(con)

print("Pipeline Complete. Data successfully staged in PostgreSQL!")