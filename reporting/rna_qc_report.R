library(exp2qcdt)

# 1. 定义您的文件路径
# meta_file <- system.file("example", "metadata_1.csv", package = "exp2qcdt")
# exp_file  <- system.file("example", "fpkm_1.csv", package = "exp2qcdt")
# count_file <- system.file("example", "count_1.csv", package = "exp2qcdt")
args <- commandArgs(trailingOnly = TRUE)
meta_file <- args[1]
exp_file <- args[2]
count_file <- args[3]
report_dir <- args[4]
report_name <- args[5]

# 2. 定义模板和输出路径
report_template <- system.file("extdata", "quartet_template.docx", package = "exp2qcdt")

# 3. 运行核心函数
result <- exp2qcdt(
  exp_table_file = exp_file,
  count_table_file = count_file,
  phenotype_file = meta_file
)

# 4. 运行报告生成函数
generate_rna_report(qc_result = result, report_template = report_template, report_dir = report_dir, report_name = report_name)
