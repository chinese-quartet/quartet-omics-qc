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

output_file <- file.path(report_dir, report_name)
result <- prot_result$conclusion$Value
write(result, file = output_file, ncolumns = length(result))
