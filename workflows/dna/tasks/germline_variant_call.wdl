task deepvariant {
	File recaled_bam
	File recaled_bam_index
	File? bed
	String grc_ref_fa
	File quartet_hc_region
	String sample = basename(recaled_bam, ".sorted.deduped.bam")
	String region = select_first([bed, quartet_hc_region])

command <<<
	set -o pipefail
	set -e
	type=WGS
	if [ ${bed} ];then
		type=WES
	fi

	/opt/deepvariant/bin/run_deepvariant \
		--model_type=$type \
		--ref=${grc_ref_fa} \
		--reads=${recaled_bam} \
		--regions=${region} \
		--output_vcf=${sample}_hc.vcf \
		--vcf_stats_report=true \
		--num_shards=$(nproc) 
	>>>

	output {
		File vcf = "${sample}_hc.vcf"
	}
}
