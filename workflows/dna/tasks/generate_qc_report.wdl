 task generate_qc_report {
	File variant_qc
	File mendelian_qc
	File? bed
	String output_dir
	String report_name

	command <<<
		set -o pipefail
		set -e
		type = "WGS"
		if [ ${bed} ];then
			type="WES"
		fi
		Rscript /opt/quartet/scripts/dna_qc_report.R ${variant_qc} ${mendelian_qc} $type ${output_dir} ${report_name}
	>>>
}
