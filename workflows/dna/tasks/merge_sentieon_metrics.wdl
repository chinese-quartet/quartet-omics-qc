task merge_sentieon_metrics {
	Array[File] quality_yield_metrics_header
	Array[File] wgs_metrics_header
	Array[File] aln_metrics_header
	Array[File] is_metrics_header
    Array[File] hs_metrics_header

	Array[File] quality_yield_metrics_data
	Array[File] wgs_metrics_data
	Array[File] aln_metrics_data
	Array[File] is_metrics_data
    Array[File] hs_metrics_data

	String project
    Int len = length(hs_metrics_header)
	
	command <<<
		echo '''Sample''' > sample_column

		cat ${sep=" " quality_yield_metrics_header} | sed -n '1,1p' | cat - ${sep=" " quality_yield_metrics_data} > quality_yield_metrics_all
		ls ${sep=" " quality_yield_metrics_data} | cut -d '.' -f1 | cat sample_column - | paste - quality_yield_metrics_all > ${project}.quality_yield_metrics.txt

		cat ${sep=" " wgs_metrics_header} | sed -n '1,1p' | cat - ${sep=" " wgs_metrics_data} > wgs_metrics_all	
		ls ${sep=" " wgs_metrics_data} | cut -d '.' -f1 | cat sample_column - | paste - wgs_metrics_all > ${project}.wgs_metrics.txt
		
		cat ${sep=" " aln_metrics_header} | sed -n '1,1p' | cat - ${sep=" " aln_metrics_data} > aln_metrics_all
		ls ${sep=" " aln_metrics_data} | cut -d '.' -f1 | cat sample_column - | paste - aln_metrics_all > ${project}.aln_metrics.txt

		cat ${sep=" " is_metrics_header} | sed -n '1,1p' | cat - ${sep=" " is_metrics_data} > is_metrics_all
		ls ${sep=" " is_metrics_data} | cut -d '.' -f1 | cat sample_column - | paste - is_metrics_all > ${project}.is_metrics.txt

        if [ "${len}" -gt "0" ]; then
            cat ${sep=" " hs_metrics_header} | sed -n '1,1p' | cat - ${sep=" " hs_metrics_data} > hs_metrics_all
		    ls ${sep=" " hs_metrics_data} | cut -d '.' -f1 | cat sample_column - | paste - hs_metrics_all > ${project}.hs_metrics.txt
        fi
	>>>

	output {
		File quality_yield_metrics_summary = "${project}.quality_yield_metrics.txt"
		File wgs_metrics_summary = "${project}.wgs_metrics.txt"
		File aln_metrics_summary = "${project}.aln_metrics.txt"
		File is_metrics_summary = "${project}.is_metrics.txt"
        File? hs_metrics_summary = "${project}.hs_metrics.txt"
	}
}
