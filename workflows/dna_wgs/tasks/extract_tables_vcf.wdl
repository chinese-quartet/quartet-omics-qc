task extract_tables_vcf {
	File hap
	String project

	command <<<
		python /opt/quartet/workflows/dna_wgs/codescripts/extract_tables.py -hap ${hap} -project ${project}
	>>>

	output {
		File variant_calling = "variants.calling.qc.txt"
	}
}
