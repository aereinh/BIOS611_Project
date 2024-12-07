library(tidyverse)
library(pheatmap)
library(DescTools)
library(philentropy)

feat_df_full <- read.csv('data/features_30_sec.csv')
feat_mat <- feat_df_full %>%
  select(-c("filename","length","label"))%>% 
  as.matrix()
cor_mat <- cor(feat_mat)

# Correlations between features
pheatmap(cor_mat)

# Correlations with label
genre <- factor(feat_df_full$label)
eta_sq_res <- apply(feat_mat, 2, function(x) {
  aov_res <- aov(x ~ genre)
  EtaSq(aov_res)[1]
})
p_vals <- apply(feat_mat, 2, function(x) {
  summary(aov(x ~ genre))[[1]][["Pr(>F)"]][1]
})
res <- data.frame(
  Feature = colnames(feat_mat),
  EtaSq = eta_sq_res,
  PValue = p_vals
)
res$AdjustedP <- p.adjust(res$PValue, method = "fdr")


# Prepare matrix for heatmap
heatmap_data <- matrix(eta_sq_res, nrow = 1, byrow = TRUE)
colnames(heatmap_data) <- colnames(feat_mat)

# Plot heatmap
pheatmap(
  heatmap_data,
  cluster_rows = FALSE,
  cluster_cols = TRUE,
  main = "Feature-Response Associations (Eta-Squared)",
  color = colorRampPalette(c("white", "blue"))(50)
)

results <- results[order(-results$EtaSq), ]

# Barplot
ggplot(res, aes(x = reorder(Feature, -EtaSq), y = EtaSq)) +
  geom_bar(stat = "identity", fill = "skyblue") +
  coord_flip() +
  labs(title = "Feature-Genre Associations", x = "Feature", y = "Eta-Squared")

ggplot(res, aes(x = reorder(Feature, PValue), y = -log10(PValue))) +
  geom_point(color = "red") +
  coord_flip() +
  labs(title = "Feature Significance", x = "Feature", y = "-log10(P-Value)")


## Characterize Genre Similarity
library(stats)
feat_mat_sc <- scale(feat_mat)
genre_means <- aggregate(feat_mat_sc, by = list(genre), FUN = mean)
row.names(genre_means) <- genre_means$Group.1
genre_means <- genre_means[,-1]
dist_mat <- dist(genre_means, method = "euclidean")
pheatmap(dist_mat, main = "Genre Similarity Heatmap (Scaled Features)")

# Hierarchical clustering
hc <- hclust(dist_mat, method = "ward.D2")

# Plot dendrogram
plot(hc, main = "Genre Similarity Dendrogram", xlab = "Genres", ylab = "Distance")

# Perform PCA
pca <- prcomp(feat_mat, center = TRUE, scale. = TRUE)

# Add genre labels to PCA results
pca_data <- as.data.frame(pca$x[, 1:2])  # Use first two PCs
pca_data$Genre <- genre

# Plot PCA
ggplot(pca_data, aes(x = PC1, y = PC2, color = Genre)) +
  geom_point(size = 3) +
  labs(title = "PCA of Genres", x = "PC1", y = "PC2") +
  theme_minimal()
