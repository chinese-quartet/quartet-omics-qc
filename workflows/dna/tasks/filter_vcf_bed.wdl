 task filter_vcf_bed {
	File vcf
	File bed
	String benchmarking_dir
	String benchmark_region
	String sample = basename(vcf,".vcf")

	command <<<
		cat ${vcf} | grep '#' > header
		cat ${vcf} | grep -v '#' > body
		cat body | grep -w '^chr1\|^chr2\|^chr3\|^chr4\|^chr5\|^chr6\|^chr7\|^chr8\|^chr9\|^chr10\|^chr11\|^chr12\|^chr13\|^chr14\|^chr15\|^chr16\|^chr17\|^chr18\|^chr19\|^chr20\|^chr21\|^chr22\|^chrX' > body.filtered
		cat header body.filtered > ${sample}.filtered.vcf

		bedtools intersect -a ${sample}.filtered.vcf -b ${bed} > body.bed.filtered
		cat header body.bed.filtered > ${sample}.chrom.bed.filtered.vcf
		bedtools intersect -a ${benchmarking_dir}/${benchmark_region} -b ${bed} > benchmark_region_query_bed.bed
	>>>

	output {
		File filtered_vcf = "${sample}.chrom.bed.filtered.vcf"
		File filtered_bed = "benchmark_region_query_bed.bed"
	}
}
