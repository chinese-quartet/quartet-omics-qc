task rename_vcf {
	String project

	File vcf
	String vcf_name = basename(vcf, ".vcf")
	String type

	command <<<
		ln -sf ${vcf} ${vcf_name}_${project}_${type}.vcf
	>>>
	output {
		File vcf_renamed = "${vcf_name}_${project}_${type}.vcf"
	}
}
