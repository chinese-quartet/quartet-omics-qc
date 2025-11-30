task sentieon {
	File quality_yield
	File wgs_metrics_algo
	File aln_metrics
	File is_metrics
	File hs_metrics

	String sample = basename(quality_yield,"_deduped_QualityYield.txt")
	String cluster_config
	String disk_size

	command <<<
		set -o pipefail	
		set -e
		cat ${quality_yield} | sed -n '7,7p' > quality_yield.header
		cat ${quality_yield} | sed -n '8,8p' > ${sample}.quality_yield
		cat ${wgs_metrics_algo} | sed -n '7,7p' > wgs_metrics_algo.header
		cat ${wgs_metrics_algo} | sed -n '8,8p' > ${sample}.wgs_metrics_algo
		cat ${aln_metrics} | sed -n '7,7p'  > aln_metrics.header
		cat ${aln_metrics} | sed -n '10,10p'  > ${sample}.aln_metrics
		cat ${is_metrics} | sed -n '7,7p' > is_metrics.header
		cat ${is_metrics} | sed -n '8,8p' > ${sample}.is_metrics

		cat ${hs_metrics} | sed -n '7,7p' > hs_metrics.header
		cat ${hs_metrics} | sed -n '8,8p' > ${sample}.hs_mtrics


	>>>

	runtime {
		cluster:cluster_config
		systemDisk:"cloud_ssd 40"
		dataDisk:"cloud_ssd " + disk_size + " /cromwell_root/"
	}

	output {
		File quality_yield_header = "quality_yield.header"
		File quality_yield_data = "${sample}.quality_yield"
		File wgs_metrics_algo_header = "wgs_metrics_algo.header"
		File wgs_metrics_algo_data = "${sample}.wgs_metrics_algo"
		File aln_metrics_header = "aln_metrics.header"
		File aln_metrics_data = "${sample}.aln_metrics"
		File is_metrics_header = "is_metrics.header"
		File is_metrics_data = "${sample}.is_metrics"
		File hs_metrics_header = "hs_metrics.header"
		File hs_metrics_data = "${sample}.hs_mtrics"		
	}
}