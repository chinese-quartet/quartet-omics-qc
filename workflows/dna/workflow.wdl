import "./tasks/benchmark.wdl" as benchmark
import "./tasks/extract_tables_vcf.wdl" as extract_tables_vcf
import "./tasks/filter_vcf.wdl" as filter_vcf
import "./tasks/generate_qc_report.wdl" as generate_qc_report
import "./tasks/merge_family.wdl" as merge_family
import "./tasks/merge_mendelian.wdl" as merge_mendelian
import "./tasks/mendelian.wdl" as mendelian
import "./tasks/multiqc_hap.wdl" as multiqc_hap
import "./tasks/rename_vcf.wdl" as rename_vcf

workflow dseqc {
	File? vcf_D5
	File? vcf_D6
	File? vcf_F7
	File? vcf_M8
	File? bed

	File quartet_d5_hc_vcf
	File quartet_d6_hc_vcf
	File quartet_f7_hc_vcf
	File quartet_m8_hc_vcf
	File quartet_hc_region
	# TODO: if declare as File instead of String, it would report error:
	#	Error: "Fasta file GRCh38.d1.vd1.fa is not indexed"
	String grc_ref_fa

	String output_dir
	String report_name
	String project

	# Fastq is null, check if starts with vcf
	if (defined(vcf_D5)) {
		call rename_vcf.rename_vcf as rename_vcf_D5_vcf{
			input:
			project=project,
			vcf=vcf_D5,
			type="LCL5",
		}
		call filter_vcf.filter_vcf as filter_vcf_D5_vcf {
			input:
			vcf=rename_vcf_D5_vcf.vcf_renamed,
			bed=bed,
			quartet_hc_region=quartet_hc_region,
		}
		call benchmark.benchmark as benchmark_D5_vcf {
			input:
			filtered_vcf=filter_vcf_D5_vcf.filtered_vcf,
			bed=filter_vcf_D5_vcf.filtered_bed,
			quartet_d5_hc_vcf=quartet_d5_hc_vcf,
			quartet_d6_hc_vcf=quartet_d6_hc_vcf,
			quartet_f7_hc_vcf=quartet_f7_hc_vcf,
			quartet_m8_hc_vcf=quartet_m8_hc_vcf,
			quartet_hc_region=quartet_hc_region,
			grc_ref_fa=grc_ref_fa,
			type="D5",
		}
	}
	if (defined(vcf_D6)) {
		call rename_vcf.rename_vcf as rename_vcf_D6_vcf{
			input:
			project=project,
			vcf=vcf_D6,
			type="LCL6",
		}
		call filter_vcf.filter_vcf as filter_vcf_D6_vcf {
			input:
			vcf=rename_vcf_D6_vcf.vcf_renamed,
			bed=bed,
			quartet_hc_region=quartet_hc_region,
		}
		call benchmark.benchmark as benchmark_D6_vcf {
			input:
			filtered_vcf=filter_vcf_D6_vcf.filtered_vcf,
			bed=filter_vcf_D6_vcf.filtered_bed,
			quartet_d5_hc_vcf=quartet_d5_hc_vcf,
			quartet_d6_hc_vcf=quartet_d6_hc_vcf,
			quartet_f7_hc_vcf=quartet_f7_hc_vcf,
			quartet_m8_hc_vcf=quartet_m8_hc_vcf,
			quartet_hc_region=quartet_hc_region,
			grc_ref_fa=grc_ref_fa,
			type="D6",
		}
	}
	if (defined(vcf_F7)) {
		call rename_vcf.rename_vcf as rename_vcf_F7_vcf{
			input:
			project=project,
			vcf=vcf_F7,
			type="LCL7",
		}
		call filter_vcf.filter_vcf as filter_vcf_F7_vcf {
			input:
			vcf=rename_vcf_F7_vcf.vcf_renamed,
			bed=bed,
			quartet_hc_region=quartet_hc_region,
		}
		call benchmark.benchmark as benchmark_F7_vcf {
			input:
			filtered_vcf=filter_vcf_F7_vcf.filtered_vcf,
			bed=filter_vcf_F7_vcf.filtered_bed,
			quartet_d5_hc_vcf=quartet_d5_hc_vcf,
			quartet_d6_hc_vcf=quartet_d6_hc_vcf,
			quartet_f7_hc_vcf=quartet_f7_hc_vcf,
			quartet_m8_hc_vcf=quartet_m8_hc_vcf,
			quartet_hc_region=quartet_hc_region,
			grc_ref_fa=grc_ref_fa,
			type="F7"
		}
	}
	if (defined(vcf_M8)) {
		call rename_vcf.rename_vcf as rename_vcf_M8_vcf{
			input:
			project=project,
			vcf=vcf_M8,
			type="LCL8",
		}
		call filter_vcf.filter_vcf as filter_vcf_M8_vcf {
			input:
			vcf=rename_vcf_M8_vcf.vcf_renamed,
			bed=bed,
			quartet_hc_region=quartet_hc_region,
		}
		call benchmark.benchmark as benchmark_M8_vcf {
			input:
			filtered_vcf=filter_vcf_M8_vcf.filtered_vcf,
			bed=filter_vcf_M8_vcf.filtered_bed,
			quartet_d5_hc_vcf=quartet_d5_hc_vcf,
			quartet_d6_hc_vcf=quartet_d6_hc_vcf,
			quartet_f7_hc_vcf=quartet_f7_hc_vcf,
			quartet_m8_hc_vcf=quartet_m8_hc_vcf,
			quartet_hc_region=quartet_hc_region,
			grc_ref_fa=grc_ref_fa,
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

	if (defined(vcf_D5) && defined(vcf_D6) && defined(vcf_F7) && defined(vcf_M8)) {
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
			grc_ref_fa=grc_ref_fa,
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
