task deduped_Metrics {

    File ref_dir
	String fasta
	File Dedup_bam
	File Dedup_bam_index
	String sample = basename(Dedup_bam,".sorted.deduped.bam")
	String docker
	String cluster_config
	String disk_size


	command <<<
		set -o pipefail
		set -e
		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar CollectAlignmentSummaryMetrics \
			-I ${Dedup_bam} \
			-O ${sample}_deduped_aln_metrics.txt \
			-R ${ref_dir}/${fasta} \
			--VALIDATION_STRINGENCY LENIENT
		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar CollectInsertSizeMetrics \
			-I ${Dedup_bam} \
			-O ${sample}_deduped_is_metrics.txt \
			-H ${sample}_deduped_is_metrics.pdf
		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar CollectQualityYieldMetrics \
			-I ${Dedup_bam} \
			-O ${sample}_deduped_QualityYield.txt

		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar CollectWgsMetrics \
			-I ${Dedup_bam} \
			-O ${sample}_deduped_WgsMetricsAlgo.txt \
			-R ${ref_dir}/${fasta} \
			--VALIDATION_STRINGENCY LENIENT

	>>>

	runtime {
		docker:docker
    	cluster: cluster_config
    	systemDisk: "cloud_ssd 40"
    	dataDisk: "cloud_ssd " + disk_size + " /cromwell_root/" 
	}

	output {
		File dedeuped_aln_metrics = "${sample}_deduped_aln_metrics.txt"
		File deduped_is_metrics = "${sample}_deduped_is_metrics.txt"
		File deduped_QualityYield = "${sample}_deduped_QualityYield.txt"
		File deduped_wgsmetrics = "${sample}_deduped_WgsMetricsAlgo.txt"
	}
}
