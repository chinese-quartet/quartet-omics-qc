 task generate_qc_report {
	File variant_qc
	File? mendelian_qc
	File? bed
	String output_dir
	String report_name

	command <<<
		set -o pipefail
		set -e
		type="WGS"
		if [ ${bed} ];then
			type="WES"
		fi
		mendelian_qc_file="null"
		if [ ${mendelian_qc} ];then
			mendelian_qc_file=${mendelian_qc}
		fi
		Rscript /opt/quartet/scripts/dna_qc_report.R ${variant_qc} $mendelian_qc_file $type ${output_dir} ${report_name}
	>>>
}
