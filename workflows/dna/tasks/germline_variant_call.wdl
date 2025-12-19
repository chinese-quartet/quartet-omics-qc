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

	pbrun deepvariant \
		--in-bam ${recaled_bam} \
		--ref ${grc_ref_fa} \
		--out-variants ${sample}_hc.vcf \
		--interval-file ${region}
	>>>

	output {
		File vcf = "${sample}_hc.vcf"
	}
}
