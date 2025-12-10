task fastq_screen {
	File read1
	File read2

	String project
	String fastq_screen_ref_dir
	String fastq_screen_ref_linking_dir
	String fastq_screen_config
	
	String sample
	String user_define_name = sub(basename(read1, "_R1.fastq.gz"), "_R1.fq.gz$", "")

	command <<<
		set -o pipefail
		set -e
		nt=$(nproc)
		mkdir -p ${fastq_screen_ref_linking_dir}
		ln -sf ${fastq_screen_ref_dir} ${fastq_screen_ref_linking_dir}
		ln -sf ${read1} ${user_define_name}_${project}_${sample}_R1.fastq.gz
		ln -sf ${read2} ${user_define_name}_${project}_${sample}_R2.fastq.gz
		fastq_screen --aligner bowtie2 --conf ${fastq_screen_config} --subset 1000000 --threads $nt ${user_define_name}_${project}_${sample}_R1.fastq.gz
		fastq_screen --aligner bowtie2 --conf ${fastq_screen_config} --subset 1000000 --threads $nt ${user_define_name}_${project}_${sample}_R2.fastq.gz
	>>>
	
	output {
		File png1 = "${user_define_name}_${project}_${sample}_R1_screen.png"
		File txt1 = "${user_define_name}_${project}_${sample}_R1_screen.txt"
		File html1 = "${user_define_name}_${project}_${sample}_R1_screen.html"
		File png2 = "${user_define_name}_${project}_${sample}_R2_screen.png"
		File txt2 = "${user_define_name}_${project}_${sample}_R2_screen.txt"
		File html2 = "${user_define_name}_${project}_${sample}_R2_screen.html"
	}
}
