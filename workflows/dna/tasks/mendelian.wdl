task mendelian {
	File family_vcf
	String grc_ref_fa
	String family_name = basename(family_vcf, ".family.vcf")
	
	command <<<
		nt=$(nproc)

		echo -e "${family_name}\tLCL8\t0\t0\t2\t-9\n${family_name}\tLCL7\t0\t0\t1\t-9\n${family_name}\tLCL5\tLCL7\tLCL8\t2\t-9" > ${family_name}.D5.ped

		mkdir VBT_D5
		vbt mendelian -ref ${grc_ref_fa} -mother ${family_vcf} -father ${family_vcf} -child ${family_vcf} -pedigree ${family_name}.D5.ped -outDir VBT_D5 -out-prefix ${family_name}.D5 --output-violation-regions -thread-count $nt

		ln -sf VBT_D5/${family_name}.D5_trio.vcf ${family_name}.D5.vcf

		echo -e "${family_name}\tLCL8\t0\t0\t2\t-9\n${family_name}\tLCL7\t0\t0\t1\t-9\n${family_name}\tLCL6\tLCL7\tLCL8\t2\t-9" > ${family_name}.D6.ped

		mkdir VBT_D6
		vbt mendelian -ref ${grc_ref_fa} -mother ${family_vcf} -father ${family_vcf} -child ${family_vcf} -pedigree ${family_name}.D6.ped -outDir VBT_D6 -out-prefix ${family_name}.D6 --output-violation-regions -thread-count $nt

		ln -sf VBT_D6/${family_name}.D6_trio.vcf ${family_name}.D6.vcf
	>>>

	output {
		File D5_ped = "${family_name}.D5.ped"
		File D6_ped = "${family_name}.D6.ped"
		Array[File] D5_mendelian = glob("VBT_D5/*")
		Array[File] D6_mendelian = glob("VBT_D6/*")
		File D5_trio_vcf = "${family_name}.D5.vcf"
		File D6_trio_vcf = "${family_name}.D6.vcf"
	}
}
