version 1.0

import "./tasks/fastp.wdl" as fastp
import "./tasks/align.wdl" as align
import "./tasks/fastdup.wdl" as fastdup
import "./tasks/strelka2.wdl" as strelka
import "./tasks/norm.wdl" as norm
import "./tasks/filter.wdl" as filter
import "./tasks/happy.wdl" as happy
import "./tasks/multiqc.wdl" as multiqc

workflow QuartetDNAPipeline {

    input {
        File? fastq_r1
        File? fastq_r2
        
        File? vcf

        String member
        File ref
        File truth_d5_vcf
        File truth_d6_vcf
        File truth_f7_vcf
        File truth_m8_vcf
        File truth_bed
        File sdf_template

        String docker_fastp
        String docker_bwa
        String docker_fastdup
        String docker_strelka
        String docker_bcftools
        String docker_happy
        String docker_multiqc
    }

    if (defined(fastq_r1) && defined(fastq_r2)) {
        call fastp.fastp {
            input:
                docker = docker_fastp,
                fq1 = select_first([fastq_r1, ""]),
                fq2 = select_first([fastq_r2, ""]),
        }

        call align.align {
            input:
                docker = docker_bwa,
                fq1 = fastp.clean_fq1,
                fq2 = fastp.clean_fq2,
                ref = ref,
        }

        call fastdup.fastdup {
            input:
                docker = docker_fastdup,
                bam = align.sorted_bam,
        }

        call strelka.strelka {
            input:
                docker = docker_strelka,
                bam = fastdup.dedup_bam,
                ref = ref,
        }

        call norm.vcfnorm {
            input:
                docker = docker_bcftools,
                raw_vcf = strelka.raw_vcf,
                ref = ref,
        }

        call filter.filter {
            input:
                docker = docker_bcftools,
                norm_vcf = vcfnorm.norm_vcf,
        }
    }

    # Fastq is null, check if starts with vcf
    if (defined(vcf)) {
        call filter.vcffilter {
            input:
                docker = docker_bcftools,
                vcf = select_first([vcf, ""]),
        }
    }

    call happy.happy {
        input:
            docker = docker_happy,
            member = member,
            query_vcf = select_first([filter.filter_vcf, vcffilter.filter_vcf]),
            truth_d5_vcf = truth_d5_vcf,
            truth_d6_vcf = truth_d6_vcf,
            truth_f7_vcf = truth_f7_vcf,
            truth_m8_vcf = truth_m8_vcf,
            truth_bed = truth_bed,
            ref = ref,
            sdf_template = sdf_template,
    }

    call multiqc.multiqc as multiqc {
        input:
            docker = docker_multiqc,
            summary = happy.summary,
    }

    output {
        File qc_file = multiqc.variant_calling
    }
}
