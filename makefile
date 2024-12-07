.PHONY: init clean all

init:
	mkdir -p derivatives
	mkdir -p figures

clean:
	rm -rf figures
	mkdir -p figures
	rm -rf derivatives
	mkdir -p derivatives

all: derivatives/pca_data.csv figures/heatmap.png figures/feat_gen_assn.png figures/gen_deng.png figures/pca_plot.png figures/test_feat.png figures/training_feat.png report.pdf

derivatives/pca_data.csv figures/pca_plot.png: scripts/pca.R
	Rscript scripts/pca.R

figures/heatmap.png figures/feat_gen_assn.png figures/gen_deng.png: scripts/eda.R
	Rscript scripts/eda.R

figures/training_feat.png: scripts/Feat_Classifiers_TrainResults.R
	Rscript scripts/Feat_Classifiers_TrainResults.R

figures/test_feat.png: scripts/Feat_Classifiers_TestResults.R
	Rscript scripts/Feat_Classifiers_TestResults.R

report.pdf: report.Rmd
	Rscript -e "rmarkdown::render('report.Rmd', output_format='pdf_document')"
