task bed_to_interval_list {

	File reference_bed_dict
    File bed
    File ref_dir
	String fasta
	String interval_list_name
	String docker
	String cluster_config
	String disk_size


	command <<<
       mkdir -p /cromwell_root/tmp
       cp ${ref_dir}/${fasta} /cromwell_root/tmp/
       cp ${reference_bed_dict} /cromwell_root/tmp/          
                  
       java -jar /usr/picard/picard.jar BedToIntervalList \
       I=${bed} \
       O=${interval_list_name}.txt \
       SD=/cromwell_root/tmp/GRCh38.d1.vd1.dict
	>>>

	runtime {
		docker:docker
    	cluster: cluster_config
    	systemDisk: "cloud_ssd 40"
    	dataDisk: "cloud_ssd " + disk_size + " /cromwell_root/" 
	}

	output {
		File interval_list = "${interval_list_name}.txt"
	}
}