 task generate_qc_report {
	File variant_qc
	File mendelian_qc
	String output_dir
	String report_name

	command <<<
		Rscript /opt/quartet/reporting/dna_qc_report.R ${variant_qc} ${mendelian_qc} ${output_dir} ${report_name}
	>>>
}
