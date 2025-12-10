task multiqc {
    Array[File] read1_zip
	Array[File] read2_zip
	Array[File] txt1
	Array[File] txt2
	Array[File] summary

	command <<<
		set -o pipefail
		set -e
        mkdir -p ./qc/fastqc
        mkdir -p ./qc/fastqscreen
		mkdir -p ./qc/benchmark
        
        cp ${sep=" " read1_zip} ${sep=" " read2_zip} ./qc/fastqc/
		cp ${sep=" " txt1} ${sep=" " txt2} ./qc/fastqscreen/
		cp ${sep=" " summary} ./qc/benchmark/
		
        /opt/venv/bin/multiqc ./qc/

        ln -sf multiqc_data/multiqc_general_stats.txt multiqc_general_stats.txt
		ln -sf multiqc_data/multiqc_fastq_screen.txt multiqc_fastq_screen.txt
		ln -sf multiqc_data/multiqc_happy_data.json multiqc_happy_data.json
	>>>

	output {
		File multiqc_html = "multiqc_report.html"
		Array[File] multiqc_txt = glob("multiqc_data/*")
        File? fastqc = "multiqc_general_stats.txt"
		File? fastqscreen = "multiqc_fastq_screen.txt"
		File hap = "multiqc_happy_data.json"
	}
}
