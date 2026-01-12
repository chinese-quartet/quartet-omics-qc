task rename_vcf {
	String project

	File vcf
	String trim_gz = basename(vcf, ".gz")
	String vcf_name = basename(trim_gz, ".vcf")
	String type

	command <<<
		if [[ ${vcf} == *.gz ]]; then
			gunzip -c ${vcf} > ${vcf_name}_${project}_${type}.vcf
		else
			ln -sf ${vcf} ${vcf_name}_${project}_${type}.vcf
		fi
	>>>
	output {
		File vcf_renamed = "${vcf_name}_${project}_${type}.vcf"
	}
}
	