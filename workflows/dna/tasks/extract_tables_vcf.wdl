task extract_tables_vcf {
	File hap
	String project

	command <<<
		python /opt/quartet/scripts/extract_tables.py -hap ${hap} -project ${project}
	>>>

	output {
		File variant_calling = "variants.calling.qc.txt"
	}
}
