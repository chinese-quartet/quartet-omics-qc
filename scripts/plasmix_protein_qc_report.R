library(PlasmixProtQC)

## example data
#expr_file <- system.file("extdata", "plasmix_somascan_test_expr.csv", package = "PlasmixProtQC")
#meta_file <- system.file("extdata", "plasmix_somascan_test_meta.csv", package = "PlasmixProtQC")
args <- commandArgs(trailingOnly = TRUE)
expr_file <- args[1]
meta_file <- args[2]
report_dir <- args[3]
report_name <- args[4]

result <- qc_conclusion(exp_path = expr_file, meta_path = meta_file)

report_template <- system.file("extdata", "Plasmix_template.docx", package = "PlasmixProtQC")

generate_protein_report(qc_result = result, report_template = report_template, report_dir = report_dir, report_name = report_name)
