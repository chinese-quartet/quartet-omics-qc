task Dedup {
	File sorted_bam
	File sorted_bam_index
	String sample = basename(sorted_bam,".sorted.bam")
	String docker
	String cluster_config
	String disk_size


	command <<<
		set -o pipefail
		set -e

		/usr/local/jdk-20.0.1/bin/java -jar /usr/local/picard.jar  MarkDuplicates \
					-I ${sorted_bam}  \
					-O ${sample}.sorted.deduped.bam \
					-M ${sample}_dedup_metrics.txt \
					--REMOVE_DUPLICATES \
					--VALIDATION_STRINGENCY LENIENT
					
		/usr/local/samtools-1.17/bin/samtools index -@ $(nproc) -o  ${sample}.sorted.deduped.bam.bai  ${sample}.sorted.deduped.bam
	>>>
	runtime {
		docker:docker
    	cluster: cluster_config
    	systemDisk: "cloud_ssd 40"
    	dataDisk: "cloud_ssd " + disk_size + " /cromwell_root/"
	}

	output {
		File Dedup_bam = "${sample}.sorted.deduped.bam"
		File Dedup_bam_index = "${sample}.sorted.deduped.bam.bai"
	}
}






