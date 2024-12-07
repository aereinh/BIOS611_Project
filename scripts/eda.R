library(dplyr)
library(pheatmap)
library(stats)
library(ggdendro)
library(RColorBrewer)
library(MASS)

feat_df_full <- read.csv('data/features_30_sec.csv')
feat_mat <- feat_df_full %>%
  select(-c("filename","length","label"))%>% 
  as.matrix()
cor_mat <- cor(feat_mat)

# Correlations between features
heatmap <- pheatmap(cor_mat, fontsize = 11)
ggsave(
  filename = "figures/heatmap.png",  # File name
  plot = heatmap,                   # The plot object to save
  width = 12,                             # Width of the plot in inches
  height = 10,                            # Height of the plot in inches
  dpi = 300                               # Resolution (dots per inch)
)

# Associations with genre (sure independence)
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
res$AdjustedP <- p.adjust(res$PValue, method = "hochberg")

feat_gen_ass_plot <- ggplot(res, aes(x = reorder(Feature, AdjustedP), y = -log10(AdjustedP))) +
  geom_bar(stat="identity", fill = "skyblue") +
  coord_flip() +
  labs(title = "Feature-Genre Associations", x = "Feature", y = "-log10(P-Value)")+
  theme_bw(base_size=18)+
  theme(axis.text.y = element_text(size = 12, angle = 0))

ggsave(
  filename = "figures/feat_gen_assn.png",  # File name
  plot = feat_gen_ass_plot,                   # The plot object to save
  width = 12,                             # Width of the plot in inches
  height = 10,                            # Height of the plot in inches
  dpi = 300                               # Resolution (dots per inch)
)

# Hierarchical clustering
hc <- hclust(dist_mat, method = "ward.D2")
dendro_data <- as.dendrogram(hc)
dendro_df <- ggdendro::dendro_data(dendro_data)

gen_dend <- ggplot() +
  geom_segment(data = dendro_df$segments, aes(x = x, y = y, xend = xend, yend = yend)) +
  geom_text(data = dendro_df$labels, aes(x = x, y = y, label = label), hjust = 0.5, vjust= 1.5, angle = 0, size = 5) +
  labs(title = "Genre Similarity Dendrogram", x = "Genres", y = "Distance") +
  theme_dendro()+
  theme(plot.title=element_text(size = 18))+
  ylim(c(-1,11))
  
ggsave(
  filename = "figures/gen_dend.png",  # File name
  plot = gen_dend,                   # The plot object to save
  width = 12,                             # Width of the plot in inches
  height = 8,                            # Height of the plot in inches
  dpi = 300                               # Resolution (dots per inch)
)