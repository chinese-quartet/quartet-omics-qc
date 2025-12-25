import "./tasks/benchmark.wdl" as benchmark
import "./tasks/dedup.wdl" as dedup
import "./tasks/deduped_metrics.wdl" as deduped_metrics
import "./tasks/extract_tables.wdl" as extract_tables
import "./tasks/extract_tables_vcf.wdl" as extract_tables_vcf
import "./tasks/fastqc.wdl" as fastqc
import "./tasks/fastq_screen.wdl" as fastq_screen
import "./tasks/filter_vcf.wdl" as filter_vcf
import "./tasks/germline_variant_call.wdl" as germline_variant_call
import "./tasks/generate_qc_report.wdl" as generate_qc_report
import "./tasks/mapping.wdl" as mapping
import "./tasks/merge_family.wdl" as merge_family
import "./tasks/merge_mendelian.wdl" as merge_mendelian
import "./tasks/merge_sentieon_metrics.wdl" as merge_sentieon_metrics
import "./tasks/mendelian.wdl" as mendelian
import "./tasks/multiqc.wdl" as multiqc
import "./tasks/multiqc_hap.wdl" as multiqc_hap
import "./tasks/qualimap.wdl" as qualimap
import "./tasks/rename_vcf.wdl" as rename_vcf
import "./tasks/sentieon.wdl" as sentieon

workflow dseqc {
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
	File? bed

	File quartet_d5_hc_vcf
	File quartet_d6_hc_vcf
	File quartet_f7_hc_vcf
	File quartet_m8_hc_vcf
	File quartet_hc_region
	# TODO: if declare as File instead of String, it would report error:
	#	Error: "Fasta file GRCh38.d1.vd1.fa is not indexed"
	String grc_ref_fa
	String? grc_ref_dict
	# TODO: if declare as File instead of String, it would copy the folder instead of symbolic linking 
	String? fastq_screen_ref_dir
	String? fastq_screen_ref_linking_dir
	String? fastq_screen_config

	String output_dir
	String report_name
	String project

	# fastq workflow
	if (defined(fastq_1_D5) && defined(fastq_2_D5)) {
		call mapping.mapping as mapping_D5 {
			input:
			project=project,
			fastq_1=fastq_1_D5,
			fastq_2=fastq_2_D5,
			grc_ref_fa=grc_ref_fa,
			group=project,
			sample='LCL5',
		}

		call fastqc.fastqc as fastqc_D5 {
			input:
			project=project,
			read1=fastq_1_D5,
			read2=fastq_2_D5,
			sample="LCL5",
		}

		call fastq_screen.fastq_screen as fastqscreen_D5 {
			input:
			read1=fastq_1_D5,
			read2=fastq_2_D5,
			project=project,
			sample="LCL5",
			fastq_screen_ref_dir=fastq_screen_ref_dir,
			fastq_screen_ref_linking_dir=fastq_screen_ref_linking_dir,
			fastq_screen_config=fastq_screen_config,
		}

		call dedup.dedup as dedup_D5 {
			input:
			sorted_bam=mapping_D5.sorted_bam,
		}

		call qualimap.qualimap as qualimap_D5 {
			input:
			bam=dedup_D5.dedup_bam,
			bai=dedup_D5.dedup_bam_index,
			bed=bed,
		}		

		call deduped_metrics.deduped_metrics as deduped_metrics_D5 {
			input:
			grc_ref_fa=grc_ref_fa,
			dedup_bam=dedup_D5.dedup_bam,
			dedup_bam_index=dedup_D5.dedup_bam_index,
			bed=bed,
			grc_ref_dict=grc_ref_dict,
		}

		call sentieon.sentieon as sentieon_D5 {
			input:
			aln_metrics=deduped_metrics_D5.deduped_aln_metrics,
			is_metrics=deduped_metrics_D5.deduped_is_metrics,
			quality_yield_metrics=deduped_metrics_D5.deduped_quality_yield_metrics,
			wgs_metrics=deduped_metrics_D5.deduped_wgs_metrics,
			hs_metrics=deduped_metrics_D5.deduped_hs_metrics,
		}

		call germline_variant_call.deepvariant as germline_variant_call_D5 {
			input:
			recaled_bam=dedup_D5.dedup_bam,
			recaled_bam_index=dedup_D5.dedup_bam_index,
			bed=bed,
			grc_ref_fa=grc_ref_fa,
			quartet_hc_region=quartet_hc_region,
		}

		call filter_vcf.filter_vcf as filter_vcf_D5 {
			input:
			vcf=germline_variant_call_D5.vcf,
			bed=bed,
			quartet_hc_region=quartet_hc_region,
		}

		call benchmark.benchmark as benchmark_D5 {
			input:
			filtered_vcf=filter_vcf_D5.filtered_vcf,
			bed=filter_vcf_D5.filtered_bed,
			quartet_d5_hc_vcf=quartet_d5_hc_vcf,
			quartet_d6_hc_vcf=quartet_d6_hc_vcf,
			quartet_f7_hc_vcf=quartet_f7_hc_vcf,
			quartet_m8_hc_vcf=quartet_m8_hc_vcf,
			quartet_hc_region=quartet_hc_region,
			grc_ref_fa=grc_ref_fa,
			type="D5",
		}
	}

	if (defined(fastq_1_D6) && defined(fastq_2_D6)) {
		call mapping.mapping as mapping_D6 {
			input:
			project=project,
			fastq_1=fastq_1_D6,
			fastq_2=fastq_2_D6,
			grc_ref_fa=grc_ref_fa,
			group=project,
			sample='LCL6',
		}

		call fastqc.fastqc as fastqc_D6 {
			input:
			project=project,
			read1=fastq_1_D6,
			read2=fastq_2_D6,
			sample="LCL6",
		}

		call fastq_screen.fastq_screen as fastqscreen_D6 {
			input:
			read1=fastq_1_D6,
			read2=fastq_2_D6,
			project=project,
			sample="LCL6",
			fastq_screen_ref_dir=fastq_screen_ref_dir,
			fastq_screen_ref_linking_dir=fastq_screen_ref_linking_dir,
			fastq_screen_config=fastq_screen_config,
		}

		call dedup.dedup as dedup_D6 {
			input:
			sorted_bam=mapping_D6.sorted_bam,
		}

		call qualimap.qualimap as qualimap_D6 {
			input:
			bam=dedup_D6.dedup_bam,
			bai=dedup_D6.dedup_bam_index,
			bed=bed,
		}		

		call deduped_metrics.deduped_metrics as deduped_metrics_D6 {
			input:
			grc_ref_fa=grc_ref_fa,
			dedup_bam=dedup_D6.dedup_bam,
			dedup_bam_index=dedup_D6.dedup_bam_index,
			bed=bed,
			grc_ref_dict=grc_ref_dict,
		}

		call sentieon.sentieon as sentieon_D6 {
			input:
			aln_metrics=deduped_metrics_D6.deduped_aln_metrics,
			is_metrics=deduped_metrics_D6.deduped_is_metrics,
			quality_yield_metrics=deduped_metrics_D6.deduped_quality_yield_metrics,
			wgs_metrics=deduped_metrics_D6.deduped_wgs_metrics,
			hs_metrics=deduped_metrics_D6.deduped_hs_metrics,
		}

		call germline_variant_call.deepvariant as germline_variant_call_D6 {
			input:
			recaled_bam=dedup_D6.dedup_bam,
			recaled_bam_index=dedup_D6.dedup_bam_index,
			bed=bed,
			grc_ref_fa=grc_ref_fa,
			quartet_hc_region=quartet_hc_region,
		}

		call filter_vcf.filter_vcf as filter_vcf_D6 {
			input:
			vcf=germline_variant_call_D6.vcf,
			bed=bed,
			quartet_hc_region=quartet_hc_region,
		}

		call benchmark.benchmark as benchmark_D6 {
			input:
			filtered_vcf=filter_vcf_D6.filtered_vcf,
			bed=filter_vcf_D6.filtered_bed,
			quartet_d5_hc_vcf=quartet_d5_hc_vcf,
			quartet_d6_hc_vcf=quartet_d6_hc_vcf,
			quartet_f7_hc_vcf=quartet_f7_hc_vcf,
			quartet_m8_hc_vcf=quartet_m8_hc_vcf,
			quartet_hc_region=quartet_hc_region,
			grc_ref_fa=grc_ref_fa,
			type="D6",
		}
	}
	if (defined(fastq_1_F7) && defined(fastq_2_F7)) {
		call mapping.mapping as mapping_F7 {
			input:
			project=project,
			fastq_1=fastq_1_F7,
			fastq_2=fastq_2_F7,
			grc_ref_fa=grc_ref_fa,
			group=project,
			sample='LCL7',
		}

		call fastqc.fastqc as fastqc_F7 {
			input:
			project=project,
			read1=fastq_1_F7,
			read2=fastq_2_F7,
			sample="LCL7",
		}

		call fastq_screen.fastq_screen as fastqscreen_F7 {
			input:
			read1=fastq_1_F7,
			read2=fastq_2_F7,
			project=project,
			sample="LCL7",
			fastq_screen_ref_dir=fastq_screen_ref_dir,
			fastq_screen_ref_linking_dir=fastq_screen_ref_linking_dir,
			fastq_screen_config=fastq_screen_config,
		}

		call dedup.dedup as dedup_F7 {
			input:
			sorted_bam=mapping_F7.sorted_bam,
		}

		call qualimap.qualimap as qualimap_F7 {
			input:
			bam=dedup_F7.dedup_bam,
			bai=dedup_F7.dedup_bam_index,
			bed=bed,
		}		

		call deduped_metrics.deduped_metrics as deduped_metrics_F7 {
			input:
			grc_ref_fa=grc_ref_fa,
			dedup_bam=dedup_F7.dedup_bam,
			dedup_bam_index=dedup_F7.dedup_bam_index,
			bed=bed,
			grc_ref_dict=grc_ref_dict,
		}

		call sentieon.sentieon as sentieon_F7 {
			input:
			aln_metrics=deduped_metrics_F7.deduped_aln_metrics,
			is_metrics=deduped_metrics_F7.deduped_is_metrics,
			quality_yield_metrics=deduped_metrics_F7.deduped_quality_yield_metrics,
			wgs_metrics=deduped_metrics_F7.deduped_wgs_metrics,
			hs_metrics=deduped_metrics_F7.deduped_hs_metrics,
		}

		call germline_variant_call.deepvariant as germline_variant_call_F7 {
			input:
			recaled_bam=dedup_F7.dedup_bam,
			recaled_bam_index=dedup_F7.dedup_bam_index,
			bed=bed,
			grc_ref_fa=grc_ref_fa,
			quartet_hc_region=quartet_hc_region,
		}

		call filter_vcf.filter_vcf as filter_vcf_F7 {
			input:
			vcf=germline_variant_call_F7.vcf,
			bed=bed,
			quartet_hc_region=quartet_hc_region,
		}

		call benchmark.benchmark as benchmark_F7 {
			input:
			filtered_vcf=filter_vcf_F7.filtered_vcf,
			bed=filter_vcf_F7.filtered_bed,
			quartet_d5_hc_vcf=quartet_d5_hc_vcf,
			quartet_d6_hc_vcf=quartet_d6_hc_vcf,
			quartet_f7_hc_vcf=quartet_f7_hc_vcf,
			quartet_m8_hc_vcf=quartet_m8_hc_vcf,
			quartet_hc_region=quartet_hc_region,
			grc_ref_fa=grc_ref_fa,
			type="F7",
		}
	}
	if (defined(fastq_1_M8) && defined(fastq_2_M8)) {
		call mapping.mapping as mapping_M8 {
			input:
			project=project,
			fastq_1=fastq_1_M8,
			fastq_2=fastq_2_M8,
			grc_ref_fa=grc_ref_fa,
			group=project,
			sample='LCL8',
		}

		call fastqc.fastqc as fastqc_M8 {
			input:
			project=project,
			read1=fastq_1_M8,
			read2=fastq_2_M8,
			sample="LCL8",
		}

		call fastq_screen.fastq_screen as fastqscreen_M8 {
			input:
			read1=fastq_1_M8,
			read2=fastq_2_M8,
			project=project,
			sample="LCL8",
			fastq_screen_ref_dir=fastq_screen_ref_dir,
			fastq_screen_ref_linking_dir=fastq_screen_ref_linking_dir,
			fastq_screen_config=fastq_screen_config,
		}

		call dedup.dedup as dedup_M8 {
			input:
			sorted_bam=mapping_M8.sorted_bam,
		}

		call qualimap.qualimap as qualimap_M8 {
			input:
			bam=dedup_M8.dedup_bam,
			bai=dedup_M8.dedup_bam_index,
			bed=bed,
		}		

		call deduped_metrics.deduped_metrics as deduped_metrics_M8 {
			input:
			grc_ref_fa=grc_ref_fa,
			dedup_bam=dedup_M8.dedup_bam,
			dedup_bam_index=dedup_M8.dedup_bam_index,
			bed=bed,
			grc_ref_dict=grc_ref_dict,
		}

		call sentieon.sentieon as sentieon_M8 {
			input:
			aln_metrics=deduped_metrics_M8.deduped_aln_metrics,
			is_metrics=deduped_metrics_M8.deduped_is_metrics,
			quality_yield_metrics=deduped_metrics_M8.deduped_quality_yield_metrics,
			wgs_metrics=deduped_metrics_M8.deduped_wgs_metrics,
			hs_metrics=deduped_metrics_M8.deduped_hs_metrics,
		}

		call germline_variant_call.deepvariant as germline_variant_call_M8 {
			input:
			recaled_bam=dedup_M8.dedup_bam,
			recaled_bam_index=dedup_M8.dedup_bam_index,
			bed=bed,
			grc_ref_fa=grc_ref_fa,
			quartet_hc_region=quartet_hc_region,
		}

		call filter_vcf.filter_vcf as filter_vcf_M8 {
			input:
			vcf=germline_variant_call_M8.vcf,
			bed=bed,
			quartet_hc_region=quartet_hc_region,
		}

		call benchmark.benchmark as benchmark_M8 {
			input:
			filtered_vcf=filter_vcf_M8.filtered_vcf,
			bed=filter_vcf_M8.filtered_bed,
			quartet_d5_hc_vcf=quartet_d5_hc_vcf,
			quartet_d6_hc_vcf=quartet_d6_hc_vcf,
			quartet_f7_hc_vcf=quartet_f7_hc_vcf,
			quartet_m8_hc_vcf=quartet_m8_hc_vcf,
			quartet_hc_region=quartet_hc_region,
			grc_ref_fa=grc_ref_fa,
			type="M8",
		}
	}

	if ((defined(fastq_1_D5) && defined(fastq_2_D5)) ||
	    (defined(fastq_1_D6) && defined(fastq_2_D6)) ||
	    (defined(fastq_1_F7) && defined(fastq_2_F7)) ||
	    (defined(fastq_1_M8) && defined(fastq_2_M8))) {
		Array[File] fastqc_read1_zip = select_all([fastqc_D5.read1_zip, fastqc_D6.read1_zip, fastqc_F7.read1_zip, fastqc_M8.read1_zip])
		Array[File] fastqc_read2_zip = select_all([fastqc_D5.read2_zip, fastqc_D6.read2_zip, fastqc_F7.read2_zip, fastqc_M8.read2_zip])
		Array[File] fastqscreen_txt1 = select_all([fastqscreen_D5.txt1, fastqscreen_D6.txt1, fastqscreen_F7.txt1, fastqscreen_M8.txt1])
		Array[File] fastqscreen_txt2 = select_all([fastqscreen_D5.txt2, fastqscreen_D6.txt2, fastqscreen_F7.txt2, fastqscreen_M8.txt2])
		Array[File] benchmark_summary = select_all([benchmark_D5.summary, benchmark_D6.summary, benchmark_F7.summary, benchmark_M8.summary])

		call multiqc.multiqc as multiqc {
			input:
			read1_zip=fastqc_read1_zip,
			read2_zip=fastqc_read2_zip,
			txt1=fastqscreen_txt1,
			txt2=fastqscreen_txt2,
			summary=benchmark_summary,
		}

		Array[File] sentieon_quality_yield_metrics_header = select_all([sentieon_D5.quality_yield_metrics_header, sentieon_D6.quality_yield_metrics_header, sentieon_F7.quality_yield_metrics_header, sentieon_M8.quality_yield_metrics_header])
		Array[File] sentieon_wgs_metrics_header = select_all([sentieon_D5.wgs_metrics_header, sentieon_D6.wgs_metrics_header, sentieon_F7.wgs_metrics_header, sentieon_M8.wgs_metrics_header])
		Array[File] sentieon_aln_metrics_header = select_all([sentieon_D5.aln_metrics_header, sentieon_D6.aln_metrics_header, sentieon_F7.aln_metrics_header, sentieon_M8.aln_metrics_header])
		Array[File] sentieon_is_metrics_header = select_all([sentieon_D5.is_metrics_header, sentieon_D6.is_metrics_header, sentieon_F7.is_metrics_header, sentieon_M8.is_metrics_header])
		Array[File] sentieon_hs_metrics_header = select_all([sentieon_D5.hs_metrics_header, sentieon_D6.hs_metrics_header, sentieon_F7.hs_metrics_header, sentieon_M8.hs_metrics_header])

		Array[File] sentieon_quality_yield_metrics_data = select_all([sentieon_D5.quality_yield_metrics_data, sentieon_D6.quality_yield_metrics_data, sentieon_F7.quality_yield_metrics_data, sentieon_M8.quality_yield_metrics_data])
		Array[File] sentieon_wgs_metrics_data = select_all([sentieon_D5.wgs_metrics_data, sentieon_D6.wgs_metrics_data, sentieon_F7.wgs_metrics_data, sentieon_M8.wgs_metrics_data])
		Array[File] sentieon_aln_metrics_data = select_all([sentieon_D5.aln_metrics_data, sentieon_D6.aln_metrics_data, sentieon_F7.aln_metrics_data, sentieon_M8.aln_metrics_data])
		Array[File] sentieon_is_metrics_data = select_all([sentieon_D5.is_metrics_data, sentieon_D6.is_metrics_data, sentieon_F7.is_metrics_data, sentieon_M8.is_metrics_data])
		Array[File] sentieon_hs_metrics_data = select_all([sentieon_D5.hs_metrics_data, sentieon_D6.hs_metrics_data, sentieon_F7.hs_metrics_data, sentieon_M8.hs_metrics_data])

		call merge_sentieon_metrics.merge_sentieon_metrics as merge_sentieon_metrics {
			input:
			quality_yield_metrics_header=sentieon_quality_yield_metrics_header,
			wgs_metrics_header=sentieon_wgs_metrics_header,
			aln_metrics_header=sentieon_aln_metrics_header,
			is_metrics_header=sentieon_is_metrics_header,
			hs_metrics_header=sentieon_hs_metrics_header,
			quality_yield_metrics_data=sentieon_quality_yield_metrics_data,
			wgs_metrics_data=sentieon_wgs_metrics_data,
			aln_metrics_data=sentieon_aln_metrics_data,
			is_metrics_data=sentieon_is_metrics_data,
			hs_metrics_data=sentieon_hs_metrics_data,
			project=project,
		}

		call extract_tables.extract_tables as extract_tables {
			input:
			quality_yield_metrics_summary=merge_sentieon_metrics.quality_yield_metrics_summary,
			wgs_metrics_summary=merge_sentieon_metrics.wgs_metrics_summary,
			aln_metrics_summary=merge_sentieon_metrics.aln_metrics_summary,
			is_metrics_summary=merge_sentieon_metrics.is_metrics_summary,
			hs_metrics_summary=merge_sentieon_metrics.hs_metrics_summary,
			fastqc=multiqc.fastqc,
			fastqscreen=multiqc.fastqscreen,
			hap=multiqc.hap,
			project=project,
		}
	}

	# vcf workflow
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

	if (defined(vcf_D5) || defined(vcf_D6) || defined(vcf_F7) || defined(vcf_M8)) {
		Array[File] benchmark_summary_hap = select_all([benchmark_D5_vcf.summary, benchmark_D6_vcf.summary, benchmark_F7_vcf.summary, benchmark_M8_vcf.summary])

		call multiqc_hap.multiqc_hap as multiqc_hap {
			input:
			summary=benchmark_summary_hap,
		}

		call extract_tables_vcf.extract_tables_vcf as extract_tables_vcf {
			input:
			hap=multiqc_hap.hap,
			project=project,
		}
	}

	if ((defined(vcf_D5) && defined(vcf_D6) && defined(vcf_F7) && defined(vcf_M8)) || 
		(defined(fastq_1_D5) && defined(fastq_1_D6) && defined(fastq_1_F7) && defined(fastq_1_M8) &&
		 defined(fastq_2_D5) && defined(fastq_2_D6) && defined(fastq_2_F7) && defined(fastq_2_M8))
	) {
		call merge_family.merge_family as merge_family_vcf {
			input:
			D5_vcf=select_first([benchmark_D5.rtg_vcf, benchmark_D5_vcf.rtg_vcf]),
			D6_vcf=select_first([benchmark_D6.rtg_vcf, benchmark_D6_vcf.rtg_vcf]),
			F7_vcf=select_first([benchmark_F7.rtg_vcf, benchmark_F7_vcf.rtg_vcf]),
			M8_vcf=select_first([benchmark_M8.rtg_vcf, benchmark_M8_vcf.rtg_vcf]),
			D5_vcf_tbi=select_first([benchmark_D5.rtg_vcf_index, benchmark_D5_vcf.rtg_vcf_index]),
			D6_vcf_tbi=select_first([benchmark_D6.rtg_vcf_index, benchmark_D6_vcf.rtg_vcf_index]),
			F7_vcf_tbi=select_first([benchmark_F7.rtg_vcf_index, benchmark_F7_vcf.rtg_vcf_index]),
			M8_vcf_tbi=select_first([benchmark_M8.rtg_vcf_index, benchmark_M8_vcf.rtg_vcf_index]),
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
		variant_qc=select_first([extract_tables.variant_calling, extract_tables_vcf.variant_calling]),
		mendelian_qc=merge_mendelian_vcf.project_mendelian_summary,
		output_dir=output_dir,
		report_name=report_name,
	}
}
