library(PlasmixMetQC)

## example data
# expr_file <- system.file("extdata", "plasmix_met_test_expr.csv", package = "PlasmixMetQC")
# meta_file <- system.file("extdata", "plasmix_met_test_meta.csv", package = "PlasmixMetQC")
args <- commandArgs(trailingOnly = TRUE)
expr_file <- args[1]
meta_file <- args[2]
report_dir <- args[3]
report_name <- args[4]
batch_name <- args[5]

result <- qc_conclusion(exp_path = expr_file, meta_path = meta_file)

report_template <- system.file("extdata", "Plasmix_template.docx", package = "PlasmixMetQC")

generate_metabo_report(qc_result = result, report_template = report_template, report_dir = report_dir, report_name = report_name, batch_name = batch_name)
