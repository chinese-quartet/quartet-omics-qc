library(metqc)

args <- commandArgs(trailingOnly = TRUE)
dt_file <- args[1]
metadata_file <- args[2]
report_dir <- args[3]
report_name <- args[4]

### get metabolomics metrics data and generate report
met_result <- get_performance(dt_file = dt_file, metadata_file = metadata_file)

output_file <- file.path(report_dir, report_name)
result <- met_result$conclusion_table$Value
write(result, file = output_file, ncolumns = length(result))
