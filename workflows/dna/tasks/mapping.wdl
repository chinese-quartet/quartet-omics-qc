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
		bwa mem -M -R "@RG\tID:${group}\tSM:${sample}\tPL:${pl}" -t $(nproc) -K 10000000 ${grc_ref_fa} ${fastq_1} ${fastq_2} \
			| samtools view -bS -@ $(nproc) - \
			| samtools sort -@ $(nproc) -o ${user_define_name}_${project}_${sample}.sorted.bam -
	>>>

	output {
		File sorted_bam = "${user_define_name}_${project}_${sample}.sorted.bam"
	}
}
