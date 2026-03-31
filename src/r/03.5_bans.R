# Load required libraries
library(ggplot2)
library(scales)

# 1. Prepare the Data
revenue_data <- data.frame(
  Category = factor(
    c("Total Potential MRR", "Retained MRR", "Lost MRR (Churn)"),
    levels = c("Total Potential MRR", "Retained MRR", "Lost MRR (Churn)")
  ),
  Amount = c(456116, 316986, 139130),
  Status = c("Total", "Retained", "Lost")
)

# 2. Build the Plot
financial_plot <- ggplot(revenue_data, aes(x = Category, y = Amount, fill = Status)) +
  # Create the bars
  geom_col(width = 0.55) +
  
  # Add the dollar amounts directly on top of the bars
  geom_text(aes(label = dollar(Amount)), 
            vjust = -0.8, 
            size = 5.5, 
            fontface = "bold", 
            color = "#2C3E50") +
  
  # Apply semantic "consulting" colors (Slate for baseline/retained, Red for lost)
  scale_fill_manual(values = c("Total" = "#BDC3C7", 
                               "Retained" = "#2C3E50", 
                               "Lost" = "#E74C3C")) +
  
  # Format the Y-axis as currency
  scale_y_continuous(labels = dollar_format(), limits = c(0, 500000)) +
  
  # Add professional labeling
  labs(
    title = "The Cost of Inaction: Monthly Revenue Bleed",
    subtitle = "High-risk attrition has eroded the portfolio's monthly earning potential by nearly 30%.",
    x = NULL,
    y = "Monthly Recurring Revenue (USD)"
  ) +
  
  # Apply a clean, minimalist theme
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "none", # Hide legend (colors are self-explanatory)
    plot.title = element_text(face = "bold", size = 18, color = "#2C3E50"),
    # FIXED: Explicitly calling ggplot2::margin to prevent randomForest conflict
    plot.subtitle = element_text(color = "#7F8C8D", margin = ggplot2::margin(b = 20), size = 13),
    panel.grid.major.x = element_blank(), # Remove vertical gridlines
    panel.grid.minor = element_blank(),   # Remove minor gridlines
    axis.text.x = element_text(face = "bold", size = 12, color = "#2C3E50"),
    # FIXED: Explicitly calling ggplot2::margin
    axis.title.y = element_text(margin = ggplot2::margin(r = 15), color = "#7F8C8D")
  )

# Display the plot
financial_plot


ggsave("visualizations/11_bans.png", 
plot = financial_plot, 
width = 8, 
height = 5.5, 
dpi = 300,
bg = "white")
cat("[System] Saved Visualization: visualizations/11_bans.png\n\n")
