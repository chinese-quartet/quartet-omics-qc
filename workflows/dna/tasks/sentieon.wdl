task sentieon {
    File aln_metrics
	File is_metrics
	File quality_yield_metrics
	File wgs_metrics
	File? hs_metrics

	String sample = basename(quality_yield_metrics, "_deduped_quality_yield_metrics.txt")

	command <<<
		set -o pipefail	
		set -e
		cat ${quality_yield_metrics} | sed -n '7,7p' > quality_yield_metrics.header
		cat ${quality_yield_metrics} | sed -n '8,8p' > ${sample}.quality_yield_metrics
		cat ${wgs_metrics} | sed -n '7,7p' > wgs_metrics.header
		cat ${wgs_metrics} | sed -n '8,8p' > ${sample}.wgs_metrics
		cat ${aln_metrics} | sed -n '7,7p'  > aln_metrics.header
		cat ${aln_metrics} | sed -n '10,10p'  > ${sample}.aln_metrics
		cat ${is_metrics} | sed -n '7,7p' > is_metrics.header
		cat ${is_metrics} | sed -n '8,8p' > ${sample}.is_metrics

		if [ ${hs_metrics} ];then
			cat ${hs_metrics} | sed -n '7,7p' > hs_metrics.header
			cat ${hs_metrics} | sed -n '8,8p' > ${sample}.hs_mtrics
		fi
	>>>

	output {
		File quality_yield_metrics_header = "quality_yield_metrics.header"
		File quality_yield_metrics_data = "${sample}.quality_yield_metrics"
		File wgs_metrics_header = "wgs_metrics.header"
		File wgs_metrics_data = "${sample}.wgs_metrics"
		File aln_metrics_header = "aln_metrics.header"
		File aln_metrics_data = "${sample}.aln_metrics"
		File is_metrics_header = "is_metrics.header"
		File is_metrics_data = "${sample}.is_metrics"
		File? hs_metrics_header = "hs_metrics.header"
		File? hs_metrics_data = "${sample}.hs_mtrics"
	}
}
