task qualimap {
	File bam
	File bai
	File bed
	String bamname = basename(bam,".bam")
	String docker
	String cluster_config
	String disk_size

	command <<<
		set -o pipefail
		set -e
		nt=$(nproc)
		awk 'BEGIN{OFS="\t"}{sub("\r","",$3);print $1,$2,$3,"",0,"."}' ${bed} > new.bed
		/opt/qualimap/qualimap bamqc -bam ${bam} -gff new.bed -outformat PDF:HTML -nt $nt -outdir ${bamname} --java-mem-size=60G

		tar -zcvf ${bamname}_qualimap.zip ${bamname}
	>>>

	runtime {
		docker:docker
		cluster:cluster_config
		systemDisk:"cloud_ssd 40"
		dataDisk:"cloud_ssd " + disk_size + " /cromwell_root/"
	}

	output {
		File zip = "${bamname}_qualimap.zip"
	}
}