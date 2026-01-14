library(PlasmixProtQC)

expr_file <- system.file("extdata", "plasmix_somascan_test_expr.csv", package = "PlasmixProtQC")
meta_file <- system.file("extdata", "plasmix_somascan_test_meta.csv", package = "PlasmixProtQC")

## Calculate QC metrics
result <- qc_conclusion(exp_path = expr_file, meta_path = meta_file)

## Generate report
report_template <- system.file("extdata", "Plasmix_template.docx", package = "PlasmixProtQC")

generate_protein_report(qc_result=result, report_template = report_template, report_name = "Plasmix_protein_report.docx")
