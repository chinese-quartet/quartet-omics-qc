library(dnaseqc)

## Read the F1 score calculation and Mendelian heritability calculation results
# variant_qc <- system.file("example", "variants.calling.qc.txt", package = "dnaseqc")
# mendelian_qc <- system.file("example", "EATRISPLUS_UU.summary.txt", package = "dnaseqc")

args <- commandArgs(trailingOnly = TRUE)
variant_qc <- args[1]
mendelian_qc <- args[2]
report_dir <- args[3]
report_name <- args[4]

## Enter the sequencing type, "WGS" or "WES", to calculate the DNAseq QC metrics.
if(variant_qc == mendelian_qc) {
  result <- dnaseqc(variant_qc_file = variant_qc, data_type = "WGS")
} else {
  result <- dnaseqc(variant_qc_file = variant_qc, data_type = "WGS", mendelian_qc_file = mendelian_qc)
}

## Generate report
### read report template from R packages
template <- system.file("extdata", "quartet_template.docx", package = "dnaseqc")
### generate QC report
generate_dna_report(qc_result = result, report_template = template, report_dir = report_dir, report_name = report_name)
