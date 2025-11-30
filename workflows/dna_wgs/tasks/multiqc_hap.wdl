task multiqc_hap {
	Array[File] summary
	String project

	command <<<
		set -o pipefail
		set -e
		mkdir -p benchmark
		cp ${sep=" " summary} benchmark/
		/opt/venv/bin/multiqc benchmark/
		cat multiqc_data/multiqc_happy_data.json > multiqc_happy_data.json
	>>>

	output {
		File multiqc_html = "multiqc_report.html"
		Array[File] multiqc_txt = glob("multiqc_data/*")
		File hap = "multiqc_happy_data.json"
	}
}
