library(metqc)

args <- commandArgs(trailingOnly = TRUE)
dt_file <- args[1]
metadata_file <- args[2]
report_dir <- args[3]
report_name <- args[4]

### get reprot template path
report_template <- system.file("extdata", "quartet_template.docx", package = "metqc")

### get metabolomics metrics data and generate report
met_result = get_performance(dt_file = dt_file, metadata_file = metadata_file)
generate_met_report(qc_result = met_result, report_template = report_template, report_dir = report_dir, report_name = report_name)
