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

# 2. 运行核心函数
result <- exp2qcdt(
  exp_table_file = exp_file,
  count_table_file = count_file,
  phenotype_file = meta_file
)

# 3. 运行报告生成函数
output_file <- file.path(report_dir, report_name)
result <- as.numeric(qc_result$qc_metrics_table$Value)
write(result, file = output_file, ncolumns = length(result))
