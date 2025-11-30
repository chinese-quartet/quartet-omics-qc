task BQSR {
	
    File ref_dir
    File dbsnp_dir
    File dbmills_dir
	String fasta
	String dbsnp
	String db_mills
	File realigned_bam
	File realigned_bam_index
	String sample = basename(realigned_bam,".sorted.deduped.realigned.bam")
	String docker
	String cluster_config
	String disk_size

	
	command <<<
		set -o pipefail
        set -e
        /usr/local/gatk-4.4.0.0/gatk BaseRecalibrator \
            -R ${ref_dir}/${fasta} \
            -I ${realigned_bam} \
            --known-sites ${dbsnp_dir}/${dbsnp} \
            --known-sites ${dbmills_dir}/${db_mills} \
            -O ${sample}_recal_data.table

        /usr/local/gatk-4.4.0.0/gatk ApplyBQSR \
            -R ${ref_dir}/${fasta} \
            -I ${realigned_bam} \
            -bqsr ${sample}_recal_data.table \
            -O ${sample}.sorted.deduped.realigned.recaled.bam

        /usr/local/samtools-1.17/bin/samtools index -@ $(nproc) -o ${sample}.sorted.deduped.realigned.recaled.bam.bai ${sample}.sorted.deduped.realigned.recaled.bam
	>>>
	runtime {
		docker:docker
		cluster: cluster_config
		systemDisk: "cloud_ssd 40"
		dataDisk: "cloud_ssd " + disk_size + " /cromwell_root/"	
	}

	output {
		File recaled_bam = "${sample}.sorted.deduped.realigned.recaled.bam"
		File recaled_bam_index = "${sample}.sorted.deduped.realigned.recaled.bam.bai"
	}
}
