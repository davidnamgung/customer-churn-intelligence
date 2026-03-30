
# EXPORT SCORED DATA FOR TABLEAU

cat("\n[System] Exporting scored dataset for Tableau Dashboard...\n")

# Attach the predicted probabilities (Risk Scores) to the original test dataset
tableau_data <- test_data
tableau_data$Churn_Risk_Score <- final_probabilities
tableau_data$Predicted_Churn <- final_predictions

# Save to the processed folder
write.csv(tableau_data, "data/processed/tableau_churn_roster.csv", row.names = FALSE)
cat("[System] Saved: data/processed/tableau_churn_roster.csv\n")