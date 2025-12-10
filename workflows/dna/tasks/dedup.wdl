task dedup {
	File sorted_bam
	String sample = basename(sorted_bam,".sorted.bam")

	command <<<
		set -o pipefail
		set -e

		java -jar /opt/picard/picard.jar MarkDuplicates \
					-I ${sorted_bam}  \
					-O ${sample}.sorted.deduped.bam \
					-M ${sample}_dedup_metrics.txt \
					--REMOVE_DUPLICATES
					
		samtools index -@ $(nproc) -o ${sample}.sorted.deduped.bam.bai ${sample}.sorted.deduped.bam
	>>>

	output {
		File dedup_bam = "${sample}.sorted.deduped.bam"
		File dedup_bam_index = "${sample}.sorted.deduped.bam.bai"
	}
}
