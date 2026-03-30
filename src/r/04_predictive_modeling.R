# (install.packages(c("randomForest", "xgboost", "caret", "gbm"))
# renv::snapshot()

# Training a Machine Learning model to predict customer churn

# Machine Learning Approach
# Divided the training data into 10 equal blocks. The model studies 9 blocks and takes a test on the 10th. Then, it throws that away, picks a different 9 blocks to study, and tests on the remaining 1. It does this 10 separate times, and we average the score.
# mathematically eliminates "bad luck." If a model scores an 85% AUC across 10 different rotating exams, you can promise with absolute certainty that the model is stable.




# ------------------------------------------------------------------------------
# 1. LOAD AND PREPARE THE DATA
# ------------------------------------------------------------------------------
# WHAT: We are loading the frozen CSV we saved in Phase 4.
# WHY: We need clean, numeric, and categorical data to feed the algorithm.
# HOW: read.csv() with stringsAsFactors = TRUE. Machine learning models in R 
#      require text categories (like "Yes"/"No" or "Male"/"Female") to be 
#      explicitly defined as "Factors" (levels) rather than plain text.
cat("======================================================\n\n")
cat(" LOADING ESSENTIAL LIBRARIES \n")
cat("======================================================\n\n")
library(caret)
library(pROC)
library(ggplot2)
library(randomForest)
# library(xgboost)
library(gbm)


cat("======================================================\n\n")
cat(" INITIATING ADVANCED ML PIPELINE \n")
cat("======================================================\n\n")
df <- read.csv("data/processed/clean_customer_intelligence.csv", stringsAsFactors = TRUE)

# Remove 'customer_id' because it is just a random string of text and has no 
# predictive value. If we leave it in, the model might get confused.
df$customer_id <- NULL
# 1. Drop any hidden empty rows
df <- na.omit(df)


## Previously tried to solve with XGBoost. Pivoted towards GBM intead.
# # ==============================================================================
# # 1.5. Fixing error with XGBoost R Compatibility
# # ==============================================================================
# cat("[System] Encoding for XGBoost compatibility...\n")

# # Create a blueprint to turn all text columns (except churn) into 1/0 numeric columns
# dummy_blueprint <- dummyVars(churn ~ ., data = df)

# # Apply the blueprint to create a completely numeric dataframe
# df_numeric <- predict(dummy_blueprint, newdata = df)
# df_numeric <- as.data.frame(df_numeric)

# # Aggressively sanitize the new column names so XGBoost's C++ engine doesn't crash
# colnames(df_numeric) <- make.names(colnames(df_numeric))

# # Add our text target variable ('churn') back onto the numeric dataframe
# df_numeric$churn <- df$churn




# ------------------------------------------------------------------------------
# 2. TRAIN / TEST SPLIT

# WHAT: We are dividing our 7,000 rows of data into two separate groups:
#       - Training Set (70%): The model uses this to learn the patterns.
#       - Testing Set (30%): The model has NEVER seen this data. We use it for a final exam.
# WHY: If we test the model on the exact same data it used to learn, it will 
#      just memorize the answers (called "Overfitting"). We need to prove it 
#      can predict churn on completely new, unseen customers.
# HOW: We use createDataPartition() from the caret package to split the data randomly.

set.seed(42) # Sets a static random starting point so our results are exactly the same every time we run this script.
train_index <- createDataPartition(df_numeric$churn, p = 0.7, list = FALSE)
train_data <- df_numeric[train_index, ]
test_data  <- df_numeric[-train_index, ]

cat("[System] Data split: 70% Training, 30% Holdout Testing.\n")




# ------------------------------------------------------------------------------
# 3. 10-FOLD CROSS-VALIDATION RULES

# WHAT: We divide the training data into 10 equal chunks. The model trains on 9 
#       chunks and tests itself on the 1st. It repeats this 10 times, rotating the test chunk.
# WHY: This prevents "lucky" splits and proves the model is universally stable.
# HOW: trainControl() establishes the rules for the upcoming Bake-Off.

cat("\n[System] Establishing 10-Fold Cross-Validation rules...\n")

cv_rules <- trainControl(
  method = "cv", 
  number = 10,
  classProbs = TRUE,                # Required to calculate AUC
  summaryFunction = twoClassSummary # Tells caret to grade based on ROC/AUC, not just Accuracy
)





# ------------------------------------------------------------------------------
# 4. TRAINING MULTIPLE MODELS

# WHAT: We train three entirely different AI architectures on the exact same data.
# 1. Logistic Regression: The classic, linear math approach.
# 2. Random Forest: Builds 500 decision trees and takes a majority vote.
# 3. XGBoost: An extreme gradient boosting engine that learns from its own mistakes sequentially.

cat("[System] Algorithm Bake-Off. This may take a few minutes...\n")

# Model 1: Logistic Regression
set.seed(42)
cat("-> Training Logistic Regression...\n")
model_glm <- train(churn ~ ., data = train_data, 
                   method = "glm", family = "binomial", 
                   metric = "ROC", trControl = cv_rules)

# Model 2: Random Forest
set.seed(42)
cat("-> Training Random Forest...\n")
model_rf <- train(churn ~ ., data = train_data, 
                  method = "rf", 
                  metric = "ROC", trControl = cv_rules)

# Model 3: XGBoost
set.seed(42)
cat("-> Training GBM (Gradient Boosting)...\n")
model_gbm <- train(churn ~ ., data = train_data,
                    method = "gbm", metric = "ROC", 
                    trControl = cv_rules, verbose = FALSE)









# ------------------------------------------------------------------------------
# 5. EVALUATE AND DECLARE WINNER
# ------------------------------------------------------------------------------
# WHAT: We collect the cross-validation scores from all three models and compare them.
# HOW: The resamples() function gathers the test scores so we can declare a statistical winner.

bakeoff_results <- resamples(list(
  Logistic = model_glm,
  RandomForest = model_rf,
  GBM = model_gbm
))

cat("\n======================================================\n")
cat(" BAKE-OFF RESULTS (AUC SCORES) \n")
cat("======================================================\n")

# Print the median AUC score for each algorithm
summary_stats <- summary(bakeoff_results)
print(summary_stats$statistics$ROC[, "Median"])

cat("\nMeaning: The algorithm with the highest median AUC score is formally declared our most predictive model.\n")
cat("======================================================\n")

# -- Visual: Bake-Off Comparison Boxplot --
cat("[System] Generating Bake-Off Comparison Visualization...\n")
p_bakeoff <- bwplot(bakeoff_results, metric = "ROC", 
                    main = "Algorithm Bake-Off: Cross-Validated AUC Scores",
                    scales = list(x = list(relation = "free"), y = list(relation = "free")))

# Note: caret's bwplot uses the lattice graphics engine, not ggplot2, so saving is slightly different
png("visualizations/06_algorithm_bakeoff.png", width = 800, height = 600, res = 120)
print(p_bakeoff)
dev.off()
cat("[System] Saved: visualizations/06_algorithm_bakeoff.png\n")



# ==============================================================================
# 6. FINAL EXAM: PREDICTING UNSEEN DATA WITH GBM

cat("\n[System] Running Final Predictions on Unseen Test Data using GBM...\n")
final_probabilities <- predict(model_gbm, test_data, type = "prob")[, "Yes"]
final_predictions <- predict(model_gbm, test_data)
actual_answers <- test_data$churn







# ==============================================================================
# 7. MODEL EVALUATION
# ==============================================================================
# We must calculate these variables first so our charts can use them!
evaluation <- confusionMatrix(final_predictions, actual_answers, positive = "Yes")
accuracy <- evaluation$overall["Accuracy"] * 100
recall   <- evaluation$byClass["Sensitivity"] * 100 

cat("\n--- FINAL TEST SET PERFORMANCE ---\n")
cat(sprintf("-> Overall Accuracy: %.2f%%\n", accuracy))
cat(sprintf("-> Recall (Sensitivity): %.2f%%\n", recall))




# ==============================================================================
# 8. MODEL VISUALIZATIONS
# ==============================================================================
cat("\n[System] Generating Model Visualizations...\n")

# -- Visual 1: Probability Distribution --
# Create a dataframe of our predictions for plotting
plot_data <- data.frame(
  Actual = test_data$churn,
  Probability = final_probabilities # Updated to the XGBoost probabilities
)

p_prob <- ggplot(plot_data, aes(x = Probability, fill = Actual)) +
  geom_density(alpha = 0.6, color = "white") +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "black", size = 1) +
  labs(title = "GBM: Probability Distribution", # Updated title
       subtitle = "Dashed line represents the 0.50 Decision Threshold.",
       x = "Predicted Probability of Churning",
       y = "Density",
       fill = "Actual Outcome") +
  theme_minimal(base_size = 14) +
  scale_fill_manual(values = c("No" = "#3498db", "Yes" = "#e74c3c"))

ggsave("visualizations/07_probability_distribution.png", plot = p_prob, width = 8, height = 5, dpi = 300)
cat("[System] Saved: visualizations/07_probability_distribution.png\n")

# -- Visual 2: Confusion Matrix Heatmap --
# Convert the matrix table into a format ggplot can read
cm_table <- as.data.frame(evaluation$table)
colnames(cm_table) <- c("Prediction", "Reference", "Freq")

p_cm <- ggplot(cm_table, aes(x = Reference, y = Prediction, fill = Freq)) +
  geom_tile(color = "white", size = 1) +
  geom_text(aes(label = Freq), vjust = 0.5, size = 8, color = "black", fontface = "bold") +
  scale_fill_gradient(low = "#ecf0f1", high = "#3498db") +
  labs(title = "Confusion Matrix: GBM Performance",
       subtitle = paste("Overall Accuracy:", round(accuracy, 1), "% | Recall:", round(recall, 1), "%"),
       x = "Actual Reality (What happened)",
       y = "Model Prediction (What the math guessed)") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none")

ggsave("visualizations/08_confusion_matrix.png", plot = p_cm, width = 6, height = 6, dpi = 300)
cat("[System] Saved: visualizations/08_confusion_matrix.png\n")
cat("======================================================\n")



# ==============================================================================
# 8. ADVANCED VISUAL DIAGNOSTICS
# ==============================================================================
cat("\n[System] Generating Advanced Diagnostics...\n")

# -- Visual 3: Feature Importance (ggplot version) --
# Extract the mathematical weights the model assigned to each feature
importance_data <- varImp(model_gbm, scale = FALSE)

# Caret stores the actual data frame inside the $importance slot for tree models
importance_df <- data.frame(
  Feature = rownames(importance_data$importance), 
  Importance = importance_data$importance$Overall
)

# Sort to find the Top 10 most impactful drivers
importance_df <- importance_df[order(-importance_df$Importance), ][1:10, ]

p_importance <- ggplot(importance_df, aes(x = reorder(Feature, Importance), y = Importance)) +
  geom_col(fill = "#2c3e50", color = "black") +
  coord_flip() + # Flip to make the feature names readable
  labs(title = "Feature Importance: Top 10 Churn Drivers (GBM)",
       subtitle = "Variables with the longest bars have the heaviest impact on the model's math.",
       x = "Customer Feature",
       y = "Importance Weight") +
  theme_minimal(base_size = 14)

ggsave("visualizations/09_feature_importance.png", plot = p_importance, width = 8, height = 5, dpi = 300)
cat("[System] Saved: visualizations/09_feature_importance.png\n")

# -- Visual 4: ROC Curve & AUC Score --
# Calculate the curve using the actual answers vs the raw predicted probabilities
roc_object <- roc(actual_answers, final_probabilities, quiet = TRUE)
auc_score <- auc(roc_object)

# Convert the ROC object into a format ggplot can use
roc_df <- data.frame(
  Specificity = roc_object$specificities,
  Sensitivity = roc_object$sensitivities
)

p_roc <- ggplot(roc_df, aes(x = 1 - Specificity, y = Sensitivity)) +
  geom_line(color = "#e74c3c", size = 1.5) +
  geom_abline(linetype = "dashed", color = "gray") + # The "Coin Flip" line
  labs(title = "ROC Curve (Final GBM Model)",
       subtitle = sprintf("AUC Score: %.3f (1.0 is perfect, 0.5 is random guessing)", auc_score),
       x = "False Positive Rate (1 - Specificity)",
       y = "True Positive Rate (Sensitivity / Recall)") +
  theme_minimal(base_size = 14) +
  annotate("text", x = 0.75, y = 0.25, label = paste("AUC =", round(auc_score, 3)), size = 6, fontface = "bold")

ggsave("visualizations/10_roc_auc_curve.png", plot = p_roc, width = 7, height = 6, dpi = 300)
cat("[System] Saved: visualizations/10_roc_auc_curve.png\n")
cat("======================================================\n")
