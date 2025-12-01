task merge_family {
	File D5_vcf
	File D6_vcf
	File F7_vcf
	File M8_vcf
	File D5_vcf_tbi
	File D6_vcf_tbi
	File F7_vcf_tbi
	File M8_vcf_tbi
	String project
	
	command <<<
		rtg vcfmerge --force-merge-all -o ${project}.family.vcf.gz ${D5_vcf} ${D6_vcf} ${F7_vcf} ${M8_vcf}
		gunzip ${project}.family.vcf.gz
	>>>

	output {
		File family_vcf = "${project}.family.vcf"
	}
}
