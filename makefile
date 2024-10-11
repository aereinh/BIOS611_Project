.PHONY: clean
.PHONY: init

init:
	mkdir -p derivatives
	mkdir -p figures
	mkdir -p logs

clean:
	rm -rf derivatives
	rm -rf figures
	rm -rf logs
	mkdir -p derivatives
	mkdir -p figures
	mkdir -p logs

report.pdf: report.Rmd
	Rscript -e "rmarkdown::render('report.Rmd', output_format='pdf_document')"
