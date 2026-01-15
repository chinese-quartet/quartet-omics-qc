task extract_tables_vcf {
	File hap
	String project
	String output_dir
	String? qc_file

	command <<<
		python2 /opt/quartet/scripts/extract_tables.py -hap ${hap} -project ${project}
		if [ ${qc_file} ];then
			cp variants.calling.qc.txt ${output_dir}/${qc_file}
		fi
	>>>

	output {
		File variant_calling = "variants.calling.qc.txt"
	}
}
