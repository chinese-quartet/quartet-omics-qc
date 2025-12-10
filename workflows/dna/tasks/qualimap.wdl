task qualimap {
	File bam
	File bai
	File? bed
	String bamname = basename(bam, ".bam")

	command <<<
		set -o pipefail
		set -e
		nt=$(nproc)

		if [ ${bed} ];then
			awk 'BEGIN{OFS="\t"}{sub("\r","",$3);print $1,$2,$3,"",0,"."}' ${bed} > new.bed
			qualimap bamqc -bam ${bam} -gff new.bed -outformat PDF:HTML -nt $nt -outdir ${bamname} --java-mem-size=60G
		else
			qualimap bamqc -bam ${bam} -outformat PDF:HTML -nt $nt -outdir ${bamname} --java-mem-size=60G
		fi

		tar -zcvf ${bamname}_qualimap.zip ${bamname}
	>>>

	output {
		File zip = "${bamname}_qualimap.zip"
	}
}
