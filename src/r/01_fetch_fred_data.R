# install.packages(c("httr2", "jsonlite", "dotenv"))
# renv::snapshot()

# Purpose: Fetches historical macroeconomic data (Inflation/CPI) from FRED API

# 1. Load Required Libraries
library(httr2)    # The modern, robust package for making API requests
library(jsonlite) # Converts the API's JSON response into a clean R dataframe
library(dotenv)   # Securely loads the hidden .Renviron file

# 2. Securely Load API Key
# This ensures we never hardcode our secret key into the script.
load_dot_env(".Renviron")
api_key <- Sys.getenv("FRED_API_KEY")

# 3. Define the API Parameters
# CPIAUCSL is the ticker for "Consumer Price Index" (Inflation) - a strong economic stressor
series_id <- "CPIAUCSL" 
base_url <- "https://api.stlouisfed.org/fred/series/observations"

print("Building API Request...")

# 4. Build the Robust API Request (The "httr2" way)
# Using the pipe operator (|>) to pass the request down a chain of commands
req <- request(base_url) |> 
  req_url_query(
    series_id = series_id,
    api_key = api_key,
    file_type = "json",
    observation_start = "2010-01-01" # Pulling data from 2010 onwards
  ) |> 
  # THE HARDCORE DETAIL: Automatic Error Handling & Retries
  # If the FRED server is busy and throws a 429 (Too Many Requests) or 503 error, 
  # this tells the script to wait and try again up to 3 times, rather than crashing.
  req_retry(max_tries = 3) 

# 5. Execute the Request
print("Sending request to Federal Reserve...")
resp <- req_perform(req)

# 6. Process the Response
# Check if the response was successful (HTTP Status 200)
if (resp_status(resp) == 200) {
  print("Success! Data received. Parsing JSON...")
  
  # Extract the raw JSON body and convert it to an R list
  raw_data <- resp_body_json(resp, simplifyVector = TRUE)
  
  # Extract just the 'observations' table (Dates and Values)
  cpi_data <- raw_data$observations
  
  # Clean up the dataframe (Keep only Date and Value columns)
  cpi_data <- cpi_data[, c("date", "value")]
  
  # Rename columns for SQL database compatibility
  colnames(cpi_data) <- c("observation_date", "cpi_value")
  
  # 7. Save to the 'data/raw' folder
  output_path <- "data/raw/fred_cpi_data.csv"
  write.csv(cpi_data, output_path, row.names = FALSE)
  
  print(paste("Pipeline Complete. Data saved to:", output_path))
  
} else {
  # If the API fails, print the error code so we know what went wrong
  print(paste("API Request Failed with status:", resp_status(resp)))
}