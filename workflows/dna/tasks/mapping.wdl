task mapping {
    File fastq_1
	File fastq_2

    String project
    String grc_ref_fa

	String group
	String sample
	String pl = "ILLUMINA"
	String user_define_name = sub(basename(fastq_1, "_R1.fastq.gz"), "_R1.fq.gz$", "")

	command <<<
		set -o pipefail
		set -e
		pbrun fq2bam \
			--ref ${grc_ref_fa} \
			--in-fq ${fastq_1} ${fastq_2} \
			--out-bam ${user_define_name}_${project}_${sample}.sorted.deduped.bam \
			--read-group-sm ${sample} --read-group-lb ${group} --read-group-pl ${pl} \
			--low-memory
	>>>

	output {
		File dedup_bam = "${user_define_name}_${project}_${sample}.sorted.deduped.bam"
		File dedup_bam_index = "${user_define_name}_${project}_${sample}.sorted.deduped.bam.bai"
	}
}
