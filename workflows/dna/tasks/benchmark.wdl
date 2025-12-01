task benchmark {
	File filtered_vcf
	File? bed
	String benchmarking_dir
	String benchmark_region
	String ref_dir
	String fasta
	String type
	String sample = basename(filtered_vcf,".filtered.vcf")
	String region = select_first([bed, benchmarking_dir + "/" + benchmark_region])

	command <<<
		set -o pipefail
		set -e
		nt=$(nproc)

		echo -e "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tLCL5" > LCL5_name
		echo -e "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tLCL6" > LCL6_name
		echo -e "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tLCL7" > LCL7_name
		echo -e "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tLCL8" > LCL8_name

		export HGREF=${ref_dir}/${fasta}

		if [[ ${type} == "D5" ]];then
			hap.py ${benchmarking_dir}/LCL5.high.confidence.calls.vcf ${filtered_vcf} -f ${region} --threads $nt -o ${sample} -r ${ref_dir}/${fasta}
			cat ${filtered_vcf} | grep '##' > header
			cat ${filtered_vcf} | grep -v '#' > body
			cat header LCL5_name body > LCL5.vcf
			rtg bgzip LCL5.vcf -c > ${sample}.reformed.vcf.gz
			rtg index -f vcf ${sample}.reformed.vcf.gz
		elif [[ ${type} == "D6" ]]; then
		    hap.py ${benchmarking_dir}/LCL6.high.confidence.calls.vcf ${filtered_vcf} -f ${region} --threads $nt -o ${sample} -r ${ref_dir}/${fasta}
			cat ${filtered_vcf} | grep '##' > header
			cat ${filtered_vcf} | grep -v '#' > body
			cat header LCL6_name body > LCL6.vcf
			rtg bgzip LCL6.vcf -c > ${sample}.reformed.vcf.gz
			rtg index -f vcf ${sample}.reformed.vcf.gz
	    elif [[ ${type} == "F7" ]]; then
	        hap.py ${benchmarking_dir}/LCL7.high.confidence.calls.vcf ${filtered_vcf} -f ${region} --threads $nt -o ${sample} -r ${ref_dir}/${fasta}
			cat ${filtered_vcf} | grep '##' > header
			cat ${filtered_vcf} | grep -v '#' > body
			cat header LCL7_name body > LCL7.vcf
			rtg bgzip LCL7.vcf -c > ${sample}.reformed.vcf.gz
			rtg index -f vcf ${sample}.reformed.vcf.gz
		elif [[ ${type} == "M8" ]]; then
			hap.py ${benchmarking_dir}/LCL8.high.confidence.calls.vcf ${filtered_vcf} -f ${region} --threads $nt -o ${sample} -r ${ref_dir}/${fasta}
			cat ${filtered_vcf} | grep '##' > header
			cat ${filtered_vcf} | grep -v '#' > body
			cat header LCL8_name body > LCL8.vcf
			rtg bgzip LCL8.vcf -c > ${sample}.reformed.vcf.gz
			rtg index -f vcf ${sample}.reformed.vcf.gz
	    else
	        echo "only for quartet samples"
	    fi
	>>>

	output {
		File rtg_vcf = "${sample}.reformed.vcf.gz"
		File rtg_vcf_index = "${sample}.reformed.vcf.gz.tbi"
		File gzip_vcf = "${sample}.vcf.gz"
		File gzip_vcf_index = "${sample}.vcf.gz.tbi"
		File roc_all_csv = "${sample}.roc.all.csv.gz"
		File roc_indel = "${sample}.roc.Locations.INDEL.csv.gz"
		File roc_indel_pass = "${sample}.roc.Locations.INDEL.PASS.csv.gz"
		File roc_snp = "${sample}.roc.Locations.SNP.csv.gz"
		File roc_snp_pass = "${sample}.roc.Locations.SNP.PASS.csv.gz"
		File summary = "${sample}.summary.csv"
		File extended = "${sample}.extended.csv"
		File metrics = "${sample}.metrics.json.gz"
	}
}
