library(dnaseqc)

## Read the F1 score calculation and Mendelian heritability calculation results
# variant_qc <- system.file("example", "variants.calling.qc.txt", package = "dnaseqc")
# mendelian_qc <- system.file("example", "EATRISPLUS_UU.summary.txt", package = "dnaseqc")

args <- commandArgs(trailingOnly = TRUE)
variant_qc <- args[1]
mendelian_qc <- args[2]
type <- args[3]
report_dir <- args[4]
report_name <- args[5]

if(variant_qc == "null") {
  result <- dnaseqc(variant_qc_file = variant_qc, data_type = type)
} else {
  result <- dnaseqc(variant_qc_file = variant_qc, data_type = type, mendelian_qc_file = mendelian_qc)
}

## Generate report
### read report template from R packages
template <- system.file("extdata", "quartet_template.docx", package = "dnaseqc")
### generate QC report
generate_dna_report(qc_result = result, report_template = template, report_dir = report_dir, report_name = report_name)
