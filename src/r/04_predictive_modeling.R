# install.packages("caret")
# renv::snapshot()


# Training a Machine Learning model to predict customer churn
# Logistic Regression is actually a classification algorithm. 
#   It is designed to answer a Yes/No question, but it does so by calculating a probability.

library(caret)
# ------------------------------------------------------------------------------
# 1. LOAD AND PREPARE THE DATA
# ------------------------------------------------------------------------------
# WHAT: We are loading the frozen CSV we saved in Phase 4.
# WHY: We need clean, numeric, and categorical data to feed the algorithm.
# HOW: read.csv() with stringsAsFactors = TRUE. Machine learning models in R 
#      require text categories (like "Yes"/"No" or "Male"/"Female") to be 
#      explicitly defined as "Factors" (levels) rather than plain text.

df <- read.csv("data/processed/clean_customer_intelligence.csv", stringsAsFactors = TRUE)

# Remove 'customer_id' because it is just a random string of text and has no 
# predictive value. If we leave it in, the model might get confused.
df$customer_id <- NULL



# ------------------------------------------------------------------------------
# 2. THE TRAIN / TEST SPLIT
# ------------------------------------------------------------------------------
# WHAT: We are dividing our 7,000 rows of data into two separate groups:
#       - Training Set (70%): The model uses this to learn the patterns.
#       - Testing Set (30%): The model has NEVER seen this data. We use it for a final exam.
# WHY: If we test the model on the exact same data it used to learn, it will 
#      just memorize the answers (called "Overfitting"). We need to prove it 
#      can predict churn on completely new, unseen customers.
# HOW: We use createDataPartition() from the caret package to split the data randomly.

set.seed(42) # Sets a static random starting point so our results are exactly the same every time we run this script.
train_index <- createDataPartition(df$churn, p = 0.7, list = FALSE)

train_data <- df[train_index, ]
test_data  <- df[-train_index, ]

cat("[System] Data successfully split: 70% Training, 30% Testing.\n")




# ------------------------------------------------------------------------------
# 3. TRAIN THE ALGORITHM (LOGISTIC REGRESSION)
# ------------------------------------------------------------------------------
# WHAT: We are training a Logistic Regression model.
# WHY: It is highly interpretable. It will calculate mathematical "weights" for 
#      every feature (e.g., Month-to-month contracts get a high risk weight).
#       - If Month-to-Month contracts are highly correlated with churn, the algorithm gives $\beta_3$ a large positive number. 
#       - If high tenure prevents churn, $\beta_1$ gets a large negative number.
# HOW: We use the glm() function (Generalized Linear Model).
#      Formula: churn ~ . means "Predict 'churn' based on ALL other columns (.)"

cat("[System] Training Logistic Regression Model... Please wait.\n")

# Note: We use family = "binomial" because our outcome has only two options (Yes/No)
churn_model <- glm(churn ~ ., data = train_data, family = "binomial")






# ------------------------------------------------------------------------------
# 4. GENERATE PREDICTIONS ON THE UNSEEN TEST DATA
# ------------------------------------------------------------------------------
# WHAT: We hand the model the Testing Set (which doesn't have the answers visible) 
#       and ask it to guess who will churn.
# WHY: This simulates deploying the model in the real world on current customers.
# HOW: The predict() function outputs a probability (0.00 to 1.00). We set a 
#      threshold at 0.50. If the probability is > 50%, we label them a "Yes" (Churner).

probabilities <- predict(churn_model, test_data, type = "response")
predictions   <- ifelse(probabilities > 0.50, "Yes", "No")
# Push every single raw $z$ scores through the Sigmoid function, and return the final probability bounded between 0.00 and 1.00.
# The model uses a Decision Threshold to make the final Yes/No call. By default, this is exactly $0.50$.
# If $P(\text{Churn}) > 0.50$, predict "Yes".
# If $P(\text{Churn}) \le 0.50$, predict "No".

# Convert our text predictions into "Factors" so we can grade them against the actual answers
predictions <- as.factor(predictions)
actual_answers <- test_data$churn





# ------------------------------------------------------------------------------
# 5. EVALUATE THE MODEL (THE CONFUSION MATRIX)
# ------------------------------------------------------------------------------
# WHAT: We compare the model's predictions to the actual reality of the Test Set.
# WHY: We need to know if the model is actually good enough to give to the CEO.
# HOW: We generate a Confusion Matrix, which grades the model's Accuracy and Recall.

evaluation <- confusionMatrix(predictions, actual_answers, positive = "Yes")

cat("\n======================================================\n")
cat(" 📈 MODEL EVALUATION RESULTS \n")
cat("======================================================\n")

# Extract the specific grades from the evaluation object
accuracy <- evaluation$overall["Accuracy"] * 100
recall   <- evaluation$byClass["Sensitivity"] * 100 

# RESULT & MEANING: Print the business translation of the math
cat(sprintf("-> Overall Accuracy: %.2f%%\n", accuracy))
cat("Meaning: Out of all the customers we tested, the model guessed their status correctly this percentage of the time.\n\n")

cat(sprintf("-> Recall (Sensitivity): %.2f%%\n", recall))
cat("Meaning: This is the most important metric. Out of all the people who ACTUALLY churned, this is the percentage our model successfully caught before they left.\n\n")

# Business Action Plan based on results
cat("--- BUSINESS CONCLUSION ---\n")
if(accuracy > 75) {
  cat("Success! The model is performing well above random guessing (which would be ~50%).\n")
  cat("Next Step: We can deploy this model to flag high-risk customers in the database, allowing the Marketing team to send them targeted discount offers BEFORE they cancel.\n")
} else {
  cat("The model needs improvement. We may need to gather more data points (like customer service call logs) to increase predictive power.\n")
}
cat("======================================================\n")






# ==============================================================================
# 6. MODEL VISUALIZATIONS
# ==============================================================================
cat("\n[System] Generating Model Visualizations...\n")

# -- Visual 1: Probability Distribution --
# Create a dataframe of our predictions for plotting
plot_data <- data.frame(
  Actual = test_data$churn,
  Probability = probabilities
)

p_prob <- ggplot(plot_data, aes(x = Probability, fill = Actual)) +
  geom_density(alpha = 0.6, color = "white") +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "black", size = 1) +
  labs(title = "Logistic Regression: Probability Distribution",
       subtitle = "Dashed line represents the 0.50 Decision Threshold.",
       x = "Predicted Probability of Churning",
       y = "Density",
       fill = "Actual Outcome") +
  theme_minimal(base_size = 14) +
  scale_fill_manual(values = c("No" = "#3498db", "Yes" = "#e74c3c")) +
  annotate("text", x = 0.25, y = max(density(plot_data$Probability)$y), label = "Predicted 'No'", size = 5) +
  annotate("text", x = 0.75, y = max(density(plot_data$Probability)$y), label = "Predicted 'Yes'", size = 5)

ggsave("visualizations/06_probability_distribution.png", plot = p_prob, width = 8, height = 5, dpi = 300)
cat("[System] Saved: visualizations/06_probability_distribution.png\n")

# -- Visual 2: Confusion Matrix Heatmap --
# Convert the matrix table into a format ggplot can read
cm_table <- as.data.frame(evaluation$table)
colnames(cm_table) <- c("Prediction", "Reference", "Freq")

p_cm <- ggplot(cm_table, aes(x = Reference, y = Prediction, fill = Freq)) +
  geom_tile(color = "white", size = 1) +
  geom_text(aes(label = Freq), vjust = 0.5, size = 8, color = "black", fontface = "bold") +
  scale_fill_gradient(low = "#ecf0f1", high = "#3498db") +
  labs(title = "Confusion Matrix: Model Performance",
       subtitle = paste("Overall Accuracy:", round(accuracy, 1), "% | Recall:", round(recall, 1), "%"),
       x = "Actual Reality (What happened)",
       y = "Model Prediction (What the math guessed)") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")

ggsave("visualizations/07_confusion_matrix.png", plot = p_cm, width = 6, height = 6, dpi = 300)
cat("[System] Saved: visualizations/07_confusion_matrix.png\n")
cat("======================================================\n")





# ==============================================================================
# 7. ADVANCED VISUAL DIAGNOSTICS (Feature Importance & ROC-AUC)
# ==============================================================================
library(pROC)
cat("\n[System] Generating Advanced Diagnostics...\n")

# -- Visual 3: Feature Importance --
# Extract the mathematical weights the model assigned to each feature
importance_data <- varImp(churn_model, scale = FALSE)
importance_df <- data.frame(Feature = rownames(importance_data), Importance = importance_data$Overall)

# Sort to find the Top 10 most impactful drivers
importance_df <- importance_df[order(-importance_df$Importance), ][1:10, ]

p_importance <- ggplot(importance_df, aes(x = reorder(Feature, Importance), y = Importance)) +
  geom_col(fill = "#2c3e50", color = "black") +
  coord_flip() + # Flip to make the feature names readable
  labs(title = "Feature Importance: Top 10 Churn Drivers",
       subtitle = "Variables with the longest bars have the heaviest impact on the model's math.",
       x = "Customer Feature",
       y = "Importance Weight") +
  theme_minimal(base_size = 14)

ggsave("visualizations/08_feature_importance.png", plot = p_importance, width = 8, height = 5, dpi = 300)
cat("[System] Saved: visualizations/08_feature_importance.png\n")

# -- Visual 4: ROC Curve & AUC Score --
# Calculate the curve using the actual answers vs the raw predicted probabilities
roc_object <- roc(actual_answers, probabilities, quiet = TRUE)
auc_score <- auc(roc_object)

# Convert the ROC object into a format ggplot can use
roc_df <- data.frame(
  Specificity = roc_object$specificities,
  Sensitivity = roc_object$sensitivities
)

p_roc <- ggplot(roc_df, aes(x = 1 - Specificity, y = Sensitivity)) +
  geom_line(color = "#e74c3c", size = 1.5) +
  geom_abline(linetype = "dashed", color = "gray") + # The "Coin Flip" line
  labs(title = "ROC Curve (Receiver Operating Characteristic)",
       subtitle = sprintf("AUC Score: %.3f (1.0 is perfect, 0.5 is random guessing)", auc_score),
       x = "False Positive Rate (1 - Specificity)",
       y = "True Positive Rate (Sensitivity / Recall)") +
  theme_minimal(base_size = 14) +
  annotate("text", x = 0.75, y = 0.25, label = paste("AUC =", round(auc_score, 3)), size = 6, fontface = "bold")

ggsave("visualizations/09_roc_auc_curve.png", plot = p_roc, width = 7, height = 6, dpi = 300)
cat("[System] Saved: visualizations/09_roc_auc_curve.png\n")
cat("======================================================\n")