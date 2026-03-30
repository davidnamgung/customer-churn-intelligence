
# EXPORT SCORED DATA FOR TABLEAU

cat("\n[System] Exporting scored dataset for Tableau Dashboard...\n")

tableau_data <- test_data
tableau_data$Churn_Risk_Score <- final_probabilities
tableau_data$Predicted_Churn <- final_predictions

write.csv(tableau_data, "data/processed/tableau_churn_roster.csv", row.names = FALSE)
cat("[System] Saved: data/processed/tableau_churn_roster.csv\n")

colnames(tableau_data)
