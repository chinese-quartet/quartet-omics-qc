task deduped_metrics {
	String grc_ref_fa
	File dedup_bam
	File dedup_bam_index
	File? bed
	String grc_ref_dict
	String sample = basename(dedup_bam, ".sorted.deduped.bam")

	command <<<
		set -o pipefail
		set -e
		java -jar /opt/picard/picard.jar CollectAlignmentSummaryMetrics \
			-I ${dedup_bam} \
			-O ${sample}_deduped_aln_metrics.txt \
			-R ${grc_ref_fa} \
			--VALIDATION_STRINGENCY LENIENT
		java -jar /opt/picard/picard.jar CollectInsertSizeMetrics \
			-I ${dedup_bam} \
			-O ${sample}_deduped_is_metrics.txt \
			-H ${sample}_deduped_is_metrics.pdf
		java -jar /opt/picard/picard.jar CollectQualityYieldMetrics \
			-I ${dedup_bam} \
			-O ${sample}_deduped_quality_yield_metrics.txt
		java -jar /opt/picard/picard.jar CollectWgsMetrics \
			-I ${dedup_bam} \
			-O ${sample}_deduped_wgs_metrics.txt \
			-R ${grc_ref_fa} \
			--VALIDATION_STRINGENCY LENIENT
		if [ ${bed} ];then
			java -jar /opt/picard/picard.jar BedToIntervalList \
				-I ${bed} \
				-O bed_interval_list.txt \
				-SD ${grc_ref_dict}
			java -jar /opt/picard/picard.jar CollectHsMetrics \
				-I ${dedup_bam} \
				-O ${sample}_deduped_hs_metrics.txt \
				--TARGET_INTERVALS bed_interval_list.txt \
				--BAIT_INTERVALS bed_interval_list.txt
		fi
	>>>

	output {
		File deduped_aln_metrics = "${sample}_deduped_aln_metrics.txt"
		File deduped_is_metrics = "${sample}_deduped_is_metrics.txt"
		File deduped_quality_yield_metrics = "${sample}_deduped_quality_yield_metrics.txt"
		File deduped_wgs_metrics = "${sample}_deduped_wgs_metrics.txt"
		File? deduped_hs_metrics = "${sample}_deduped_hs_metrics.txt"
	}
}
