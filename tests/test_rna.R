library(exp2qcdt)

## please prepare your input file in the following format. (Make sure the column names are the same format with the example)
rna_sample_fpkm <- system.file("example", "fpkm.csv", package = "exp2qcdt")
rna_sample_count <- system.file("example", "count.csv", package = "exp2qcdt")
rna_sample_metadata <- system.file("example", "metadata.csv", package = "exp2qcdt")

result <- exp2qcdt(exp_table_file = rna_sample_fpkm, count_table_file = rna_sample_count, phenotype_file = rna_sample_metadata)

## Get QC report template file path 
report_template <- system.file("extdata", "quartet_template.docx", package = "exp2qcdt")

##  Generate QC report
generate_rna_report(qc_result = result, report_template = report_template)
