task Haplotyper {
    File ref_dir
	String fasta
	File recaled_bam
	File recaled_bam_index
	String sample = basename(recaled_bam,".sorted.deduped.realigned.recaled.bam")
	String docker
	String cluster_config
	String disk_size

command <<<
		set -o pipefail
		set -e
		/opt/deepvariant/bin/run_deepvariant \
			--model_type=WGS \
			--ref=${ref_dir}/${fasta} \
			--reads=${recaled_bam} \
			--output_vcf=${sample}_hc.vcf \
			--num_shards=$(nproc) 
	>>>
	
	runtime {
		docker:docker
    	cluster: cluster_config
    	systemDisk: "cloud_ssd 40"
    	dataDisk: "cloud_ssd " + disk_size + " /cromwell_root/"
	}

	output {
		File vcf = "${sample}_hc.vcf"
	}
}


