library(PlasmixProtQC)

## example data
#expr_file <- system.file("extdata", "plasmix_somascan_test_expr.csv", package = "PlasmixProtQC")
#meta_file <- system.file("extdata", "plasmix_somascan_test_meta.csv", package = "PlasmixProtQC")
args <- commandArgs(trailingOnly = TRUE)
expr_file <- args[1]
meta_file <- args[2]
report_dir <- args[3]
report_name <- args[4]

qc_res <- qc_conclusion(exp_path = expr_file, meta_path = meta_file)

output_file <- file.path(report_dir, report_name)
result <- qc_res$qc_metrics_table$Value
write(result, file = output_file, ncolumns = length(result))
