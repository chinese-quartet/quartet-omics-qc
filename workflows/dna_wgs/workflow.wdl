import "./tasks/rename_fastq.wdl" as rename_fastq
import "./tasks/rename_vcf.wdl" as rename_vcf
import "./tasks/mapping.wdl" as mapping
import "./tasks/Dedup.wdl" as Dedup
import "./tasks/qualimap.wdl" as qualimap
import "./tasks/deduped_Metrics.wdl" as deduped_Metrics
import "./tasks/sentieon.wdl" as sentieon
import "./tasks/Realigner.wdl" as Realigner
import "./tasks/BQSR.wdl" as BQSR
import "./tasks/Haplotyper.wdl" as Haplotyper
import "./tasks/benchmark.wdl" as benchmark
import "./tasks/multiqc.wdl" as multiqc
import "./tasks/multiqc_hap.wdl" as multiqc_hap
import "./tasks/merge_sentieon_metrics.wdl" as merge_sentieon_metrics
import "./tasks/extract_tables.wdl" as extract_tables
import "./tasks/extract_tables_vcf.wdl" as extract_tables_vcf
import "./tasks/mendelian.wdl" as mendelian
import "./tasks/merge_mendelian.wdl" as merge_mendelian
import "./tasks/quartet_mendelian.wdl" as quartet_mendelian
import "./tasks/fastqc.wdl" as fastqc
import "./tasks/fastqscreen.wdl" as fastqscreen
import "./tasks/merge_family.wdl" as merge_family
import "./tasks/filter_vcf.wdl" as filter_vcf
import "./tasks/generate_qc_report.wdl" as generate_qc_report

workflow {{ project_name }} {
	File? fastq_1_D5
	File? fastq_1_D6
	File? fastq_1_F7
	File? fastq_1_M8

	File? fastq_2_D5
	File? fastq_2_D6
	File? fastq_2_F7
	File? fastq_2_M8

	File? vcf_D5
	File? vcf_D6
	File? vcf_F7
	File? vcf_M8

	String REPLACE_SENTIEON_DOCKER
	String DEEPVARIANT_DOCKER
	String FASTQCdocker
	String FASTQSCREENdocker
	String QUALIMAPdocker
	String BENCHMARKdocker
	String MENDELIANdocker
	String DIYdocker
	String MULTIQCdocker
	String BEDTOOLSdocker

	String fasta
	File dbmills_dir
	String db_mills
	File dbsnp_dir
	String dbsnp
	String pl

	File screen_ref_dir
	File fastq_screen_conf
	String benchmarking_dir
	String ref_dir
	String output_dir
	String report_name

	String project

	String disk_size
	String BIGcluster_config
	String SMALLcluster_config

	# Fastq is null, check if starts with vcf
	if (vcf_D5 != "") {
		call rename_vcf.rename_vcf as rename_vcf_D5_vcf{
			input:
			project=project,
			vcf=vcf_D5,
			type="LCL5",
		}
		call filter_vcf.filter_vcf as filter_vcf_D5_vcf {
			input:
			vcf=rename_vcf_D5_vcf.vcf_renamed,
		}
		call benchmark.benchmark as benchmark_D5_vcf {
			input:
			filtered_vcf=filter_vcf_D5_vcf.filtered_vcf,
			benchmarking_dir=benchmarking_dir,
			ref_dir=ref_dir,
			type="D5",
		}
	}
	if (vcf_D6 != "") {
		call rename_vcf.rename_vcf as rename_vcf_D6_vcf{
			input:
			project=project,
			vcf=vcf_D6,
			type="LCL6",
		}
		call filter_vcf.filter_vcf as filter_vcf_D6_vcf {
			input:
			vcf=rename_vcf_D6_vcf.vcf_renamed,		
		}
		call benchmark.benchmark as benchmark_D6_vcf {
			input:
			filtered_vcf=filter_vcf_D6_vcf.filtered_vcf,
			benchmarking_dir=benchmarking_dir,
			ref_dir=ref_dir,
			type="D6",
		}
	}
	if (vcf_F7 != "") {
		call rename_vcf.rename_vcf as rename_vcf_F7_vcf{
			input:
			project=project,
			vcf=vcf_F7,
			type="LCL7",
		}
		call filter_vcf.filter_vcf as filter_vcf_F7_vcf {
			input:
			vcf=rename_vcf_F7_vcf.vcf_renamed,	
		}
		call benchmark.benchmark as benchmark_F7_vcf {
			input:
			filtered_vcf=filter_vcf_F7_vcf.filtered_vcf,
			benchmarking_dir=benchmarking_dir,
			ref_dir=ref_dir,
			type="F7"
		}
	}
	if (vcf_M8 != "") {
		call rename_vcf.rename_vcf as rename_vcf_M8_vcf{
			input:
			project=project,
			vcf=vcf_M8,
			type="LCL8",
		}
		call filter_vcf.filter_vcf as filter_vcf_M8_vcf {
			input:
			vcf=rename_vcf_M8_vcf.vcf_renamed,	
		}
		call benchmark.benchmark as benchmark_M8_vcf {
			input:
			filtered_vcf=filter_vcf_M8_vcf.filtered_vcf,
			benchmarking_dir=benchmarking_dir,
			ref_dir=ref_dir,
			type="M8"
		}
	}

	Array[File] benchmark_summary_hap = select_all([benchmark_D5_vcf.summary, benchmark_D6_vcf.summary, benchmark_F7_vcf.summary, benchmark_M8_vcf.summary])

	call multiqc_hap.multiqc_hap as multiqc_hap {
		input:
		summary=benchmark_summary_hap,
		project=project,
	}

	call extract_tables_vcf.extract_tables_vcf as extract_tables_vcf {
		input:
		hap=multiqc_hap.hap,
		project=project,
	}

	if (vcf_D5 != "" && vcf_D6 != "" && vcf_F7 != "" && vcf_M8 != "") {
		call merge_family.merge_family as merge_family_vcf {
			input:
			D5_vcf=benchmark_D5_vcf.rtg_vcf,
			D6_vcf=benchmark_D6_vcf.rtg_vcf,
			F7_vcf=benchmark_F7_vcf.rtg_vcf,
			M8_vcf=benchmark_M8_vcf.rtg_vcf,
			D5_vcf_tbi=benchmark_D5_vcf.rtg_vcf_index,
			D6_vcf_tbi=benchmark_D6_vcf.rtg_vcf_index,
			F7_vcf_tbi=benchmark_F7_vcf.rtg_vcf_index,
			M8_vcf_tbi=benchmark_M8_vcf.rtg_vcf_index,
			project=project,
		}

		call mendelian.mendelian as mendelian_vcf {
			input:
			family_vcf=merge_family_vcf.family_vcf,
			ref_dir=ref_dir,
			fasta="GRCh38.d1.vd1.fa",
		}

		call merge_mendelian.merge_mendelian as merge_mendelian_vcf {
			input:
			D5_trio_vcf=mendelian_vcf.D5_trio_vcf,
			D6_trio_vcf=mendelian_vcf.D6_trio_vcf,
			family_vcf=merge_family_vcf.family_vcf,
		}
	}

	call generate_qc_report.generate_qc_report as generate_qc_report {
		input:
		variant_qc=extract_tables_vcf.variant_calling,
		mendelian_qc=select_first([merge_mendelian_vcf.project_mendelian_summary, extract_tables_vcf.variant_calling]),
		output_dir=output_dir,
		report_name=report_name,
	}
}
