task mapping {

    File ref_dir
    String fasta
	File fastq_1
	File fastq_2

	String group
	String sample
	String project
	String pl
	String user_define_name = sub(basename(fastq_1, "_R1.fastq.gz"), "_R1.fq.gz$", "")
	String docker
	String cluster_config
	String disk_size

	command <<<
		set -o pipefail
		set -e	
		bwa mem -M -R "@RG\tID:${group}\tSM:${sample}\tPL:${pl}" -t $(nproc) -K 10000000 ${ref_dir}/${fasta} ${fastq_1} ${fastq_2} \
			| samtools view -bS -@ $(nproc) - \
			| samtools sort -@ $(nproc) -o ${user_define_name}_${project}_${sample}.sorted.bam -
		
		samtools index -@ $(nproc) \
						-o ${user_define_name}_${project}_${sample}.sorted.bam.bai  \
						${user_define_name}_${project}_${sample}.sorted.bam
	>>>

	runtime {
		docker:docker
    	cluster: cluster_config
    	systemDisk: "cloud_ssd 40"
    	dataDisk: "cloud_ssd " + disk_size + " /cromwell_root/"
	}
	output {
		File sorted_bam = "${user_define_name}_${project}_${sample}.sorted.bam"
		File sorted_bam_index = "${user_define_name}_${project}_${sample}.sorted.bam.bai"
	}
}
