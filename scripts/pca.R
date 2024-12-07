library(dplyr)
library(ggplot2)
feat_df_full <- read.csv('data/features_30_sec.csv')
feat_mat <- feat_df_full %>%
  dplyr::select(-c("filename","length","label"))%>% 
  as.matrix()

# PCA
pca <- prcomp(feat_mat, center = T, scale. = T)

# Add genre labels to PCA results
pca_data <- as.data.frame(pca$x)  # Use first two PCs
pca_data$Genre <- feat_df_full$label
pca_data$filename <- feat_df_full$filename

# Identify outliers
pca_data <- pca_data %>%
  mutate(PC1_z = (PC1 - mean(PC1)) / sd(PC1),
         PC2_z = (PC2 - mean(PC2)) / sd(PC2),
         global_outlier = abs(PC1_z) > 3 | abs(PC2_z) > 3) %>%
  group_by(Genre) %>%
  mutate(
    PC1_z_g = (PC1 - mean(PC1)) / sd(PC1),
    PC2_z_g = (PC2 - mean(PC2)) / sd(PC2),
    genre_outlier = abs(PC1_z_g) > 3 | abs(PC2_z_g) > 3  # Flag outliers (e.g., > 3 SD)
  )
write.csv(pca_data, 'derivatives/pca_data.csv')

# Plot PCA
pca_plot <- ggplot(pca_data, aes(x = PC1, y = PC2, color = Genre, shape = global_outlier)) +
  geom_point(size = 3, alpha = .9) +
  scale_color_brewer(palette = "Paired") +  # For points and ellipse borders
  scale_shape_manual(values = c(16, 8)) +  # 16 = circle (normal), 8 = star (outlier)
  labs(title = "PCs by Genres", x = "PC1", y = "PC2", shape = "Outlier") +
  theme_bw(base_size=18)

ggsave(
  filename = "figures/pca_plot.png",  # File name
  plot = pca_plot,                   # The plot object to save
  width = 12,                             # Width of the plot in inches
  height = 8,                            # Height of the plot in inches
  dpi = 300                               # Resolution (dots per inch)
)

