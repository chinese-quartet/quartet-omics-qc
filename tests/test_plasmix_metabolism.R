library(PlasmixMetQC)

expr_file <- system.file("extdata", "plasmix_met_test_expr.csv", package = "PlasmixMetQC")
meta_file <- system.file("extdata", "plasmix_met_test_meta.csv", package = "PlasmixMetQC")

## Calculate QC metrics
result <- qc_conclusion(exp_path = expr_file, meta_path = meta_file)

## Generate report
report_template <- system.file("extdata", "Plasmix_template.docx", package = "PlasmixMetQC")

generate_metabo_report(qc_result=result, report_template = report_template, report_name = "Plasmix_metabolism_report.docx")
