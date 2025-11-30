library(protqc)

## example data
# example_prot_data_path <- system.file("extdata","proteomics_pipeline_data_template.csv",package = "protqc")
# example_prot_metadata_path <- system.file("extdata","proteomics_pipeline_meta_template.csv",package = "protqc")
args <- commandArgs(trailingOnly = TRUE)
prot_data <- args[1]
prot_metadata <- args[2]
report_dir <- args[3]
report_name <- args[4]

prot_result <- protqc::qc_conclusion(prot_data, prot_metadata)

report_template <- system.file("extdata", "quartet_template.docx", package = "protqc")

generate_protein_report(qc_result = prot_result, report_template = report_template, report_dir = report_dir, report_name = report_name)
