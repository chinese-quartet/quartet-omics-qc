#!/opt/venv/bin/python

import click
import json
import os
import re
import shutil
import threading
from subprocess import Popen, PIPE


def call_cromwell(inputs_file, workflow_file, tasks_file, workflow_root):
    executions_dir = os.path.join(workflow_root, "cromwell-executions")
    logs_dir = os.path.join(workflow_root, "cromwell-workflow-logs")
    executions_dir_option = '-Dbackend.providers.Local.config.root=' + executions_dir
    logs_dir_option = '-Dworkflow-options.workflow-log-dir=' + logs_dir
    cmd = ['java', '-Dconfig.file=/opt/cromwell/cromwell-local.conf', executions_dir_option, logs_dir_option,
            '-jar', '/opt/cromwell/cromwell.jar', 'run', workflow_file, "-i", inputs_file,
            "-p", tasks_file, "--workflow-root", workflow_root]
    proc = Popen(cmd, stdin=PIPE)
    proc.communicate()


@click.group()
def omics_qc():
    pass


@omics_qc.command(help="Run the pipeline for DNA-Seq FASTQ data.")
@click.option('--d5-r1', required=False, multiple=True,
              type=click.Path(exists=True, dir_okay=False, file_okay=True),
              help="D5 Read1 File.")
@click.option('--d5-r2', required=False, multiple=True,
              type=click.Path(exists=True, dir_okay=False, file_okay=True),
              help="D5 Read2 File.")
@click.option('--d6-r1', required=False, multiple=True,
              type=click.Path(exists=True, dir_okay=False, file_okay=True),
              help="D6 Read1 File.")
@click.option('--d6-r2', required=False, multiple=True,
              type=click.Path(exists=True, dir_okay=False, file_okay=True),
              help="D6 Read2 File.")
@click.option('--f7-r1', required=False, multiple=True,
              type=click.Path(exists=True, dir_okay=False, file_okay=True),
              help="F7 Read1 File.")
@click.option('--f7-r2', required=False, multiple=True,
              type=click.Path(exists=True, dir_okay=False, file_okay=True),
              help="F7 Read2 File.")
@click.option('--m8-r1', required=False, multiple=True,
              type=click.Path(exists=True, dir_okay=False, file_okay=True),
              help="M8 Read1 File.")
@click.option('--m8-r2', required=False, multiple=True,
              type=click.Path(exists=True, dir_okay=False, file_okay=True),
              help="M8 Read2 File.")
@click.option('--bed-file', '-b', required=False,
              type=click.Path(exists=True, dir_okay=False, file_okay=True),
              help="A bed file for your wes data.")
@click.option('--reference-data-dir', '-R', required=True,
              type=click.Path(exists=True, dir_okay=True, file_okay=False),
              help="A directory which contains reference data files.")
@click.option('--output-dir', required=False,
              type=click.Path(exists=True, dir_okay=True, file_okay=False),
              help="The output directory.")
def dna_fq_workflow(d5_r1, d5_r2, d6_r1, d6_r2, f7_r1, f7_r2, m8_r1, m8_r2,
                    bed_file, output_dir, reference_data_dir):
    for item in d5_r1 + d6_r1 + f7_r1 + m8_r1 + d5_r2 + d6_r2 + f7_r2 + m8_r2:
        if not re.match(r'.*.(fastq|fq).gz', item):
            raise Exception(
                "The file (%s) must be in format of .fastq.gz or .fq.gz" % item)
    
    if len(d5_r1) != len(d5_r2) or len(d6_r1) != len(d6_r2) or len(f7_r1) != len(f7_r2) or len(m8_r1) != len(m8_r2):
        raise Exception(
            "File R1.fastq.gz and R2.fq.gz must be specified in pairs")

    max_len = max([len(d5_r1), len(d6_r1), len(f7_r1), len(m8_r1)])
    min_len = min([len(d5_r1), len(d6_r1), len(f7_r1), len(m8_r1)])
    if (max_len - min_len) > 1:
        raise Exception(
            "The fastq files number should be 4 * x + δ(δ < 4)")

    workflow_file = "/opt/quartet/workflows/dna/workflow.wdl"
    ## tasks.zip is the zipped tarball of tasks folder and will be auto generated in dockerfile
    tasks_tarball = "/opt/quartet/workflows/dna/tasks.zip"

    threads = []
    project_name = "dseqc"
    output_workflow_dir = os.path.join(output_dir, "cromwell-workflows", project_name)
    os.makedirs(output_workflow_dir, exist_ok=True)

    quartet_ref_dir = os.path.join(reference_data_dir, "reference_datasets_v202103")
    quartet_d5_hc_vcf = os.path.join(quartet_ref_dir, "LCL5.high.confidence.calls.vcf")
    quartet_d6_hc_vcf = os.path.join(quartet_ref_dir, "LCL6.high.confidence.calls.vcf")
    quartet_f7_hc_vcf = os.path.join(quartet_ref_dir, "LCL7.high.confidence.calls.vcf")
    quartet_m8_hc_vcf = os.path.join(quartet_ref_dir, "LCL8.high.confidence.calls.vcf")
    quartet_hc_region = os.path.join(quartet_ref_dir, "Quartet.high.confidence.region.v202103.bed")
    grc_ref_fa = os.path.join(reference_data_dir, "GRCh38.d1.vd1", "GRCh38.d1.vd1.fa")
    grc_ref_dict = os.path.join(reference_data_dir, "GRCh38.d1.vd1", "GRCh38.d1.vd1.dict")
    fastq_screen_ref_dir = os.path.join(reference_data_dir, "fastq_screen_reference")
    fastq_screen_ref_linking_dir = "/cromwell_root/tmp/"
    fastq_screen_config = os.path.join(fastq_screen_ref_dir, "fastq_screen.conf")

    for i in range(max_len):
        report_name = "Quartet_DNA_Report_" + str(i) + ".docx"

        data_dict = {
            "project": project_name,
            "quartet_d5_hc_vcf": quartet_d5_hc_vcf,
            "quartet_d6_hc_vcf": quartet_d6_hc_vcf,
            "quartet_f7_hc_vcf": quartet_f7_hc_vcf,
            "quartet_m8_hc_vcf": quartet_m8_hc_vcf,
            "quartet_hc_region": quartet_hc_region,
            "grc_ref_fa": grc_ref_fa,
            "grc_ref_dict": grc_ref_dict,
            "fastq_screen_ref_dir": fastq_screen_ref_dir,
            "fastq_screen_ref_linking_dir": fastq_screen_ref_linking_dir,
            "fastq_screen_config": fastq_screen_config,
            "output_dir": output_dir,
            "report_name": report_name,
        }
        if len(d5_r1) > i:
            data_dict["fastq_1_D5"] = d5_r1[i]
            data_dict["fastq_2_D5"] = d5_r2[i]
        if len(d6_r1) > i:
            data_dict["fastq_1_D6"] = d6_r1[i]
            data_dict["fastq_2_D6"] = d6_r2[i]
        if len(f7_r1) > i:
            data_dict["fastq_1_F7"] = f7_r1[i]
            data_dict["fastq_2_F7"] = f7_r2[i]
        if len(m8_r1) > i:
            data_dict["fastq_1_M8"] = m8_r1[i]
            data_dict["fastq_2_M8"] = m8_r2[i]
        if bed_file:
            data_dict["bed"] = bed_file

        input_dict = {}
        for key, value in data_dict.items():
            input_dict[project_name + "." + key] = value
        inputs_file = os.path.join(output_workflow_dir, "inputs_" + str(i))
        with open(inputs_file, 'w') as fp:
            json.dump(input_dict, fp, indent=4)

        thread = threading.Thread(target=call_cromwell, args=(inputs_file, workflow_file, tasks_tarball, output_dir))
        thread.daemon = True
        thread.start()
        threads.append(thread)

    for t in threads:
        t.join()
    
    print('DNA fastq workflow and output results to %s.' % output_dir)


@omics_qc.command(help="Run the pipeline for DNA-Seq VCF data.")
@click.option('--vcf-d5', required=False, multiple=True,
              type=click.Path(exists=True, file_okay=True),
              help="D5 VCF Files.")
@click.option('--vcf-d6', required=False, multiple=True,
              type=click.Path(exists=True, file_okay=True),
              help="D6 VCF Files.")
@click.option('--vcf-f7', required=False, multiple=True,
              type=click.Path(exists=True, file_okay=True),
              help="F7 VCF Files.")
@click.option('--vcf-m8', required=False, multiple=True,
              type=click.Path(exists=True, file_okay=True),
              help="M8 VCF Files.")
@click.option('--bed-file', '-b', required=False,
              type=click.Path(exists=True, file_okay=True),
              help="A bed file for your wes data.")
@click.option('--reference-data-dir', '-R', required=True,
              type=click.Path(exists=True, dir_okay=True, file_okay=False),
              help="A directory which contains reference data files.")
@click.option('--output-dir', required=True,
              type=click.Path(exists=True, dir_okay=True),
              help="The output directory.")
def dna_vcf_workflow(vcf_d5, vcf_d6, vcf_f7, vcf_m8, bed_file, output_dir, reference_data_dir):
    for item in vcf_d5 + vcf_d6 + vcf_f7 + vcf_m8:
        if not re.match(r'.*.vcf', item):
            raise Exception(
                "The file (%s) must be in format of .vcf" % item)
    
    max_len = max([len(vcf_d5), len(vcf_d6), len(vcf_f7), len(vcf_m8)])
    min_len = min([len(vcf_d5), len(vcf_d6), len(vcf_f7), len(vcf_m8)])
    if (max_len - min_len) > 1:
        raise Exception(
            "The vcf files number should be 4 * x + δ(δ < 4)")

    workflow_file = "/opt/quartet/workflows/dna/workflow.wdl"
    ## tasks.zip is the zipped tarball of tasks folder and will be auto generated in dockerfile
    tasks_tarball = "/opt/quartet/workflows/dna/tasks.zip"

    threads = []
    project_name = "dseqc"
    output_workflow_dir = os.path.join(output_dir, "cromwell-workflows", project_name)
    os.makedirs(output_workflow_dir, exist_ok=True)

    quartet_ref_dir = os.path.join(reference_data_dir, "reference_datasets_v202103")
    quartet_d5_hc_vcf = os.path.join(quartet_ref_dir, "LCL5.high.confidence.calls.vcf")
    quartet_d6_hc_vcf = os.path.join(quartet_ref_dir, "LCL6.high.confidence.calls.vcf")
    quartet_f7_hc_vcf = os.path.join(quartet_ref_dir, "LCL7.high.confidence.calls.vcf")
    quartet_m8_hc_vcf = os.path.join(quartet_ref_dir, "LCL8.high.confidence.calls.vcf")
    quartet_hc_region = os.path.join(quartet_ref_dir, "Quartet.high.confidence.region.v202103.bed")
    grc_ref_fa = os.path.join(reference_data_dir, "GRCh38.d1.vd1", "GRCh38.d1.vd1.fa")

    for i in range(max_len):
        report_name = "Quartet_DNA_Report_" + str(i) + ".docx"

        data_dict = {
            "project": project_name,
            "quartet_d5_hc_vcf": quartet_d5_hc_vcf,
            "quartet_d6_hc_vcf": quartet_d6_hc_vcf,
            "quartet_f7_hc_vcf": quartet_f7_hc_vcf,
            "quartet_m8_hc_vcf": quartet_m8_hc_vcf,
            "quartet_hc_region": quartet_hc_region,
            "grc_ref_fa": grc_ref_fa,
            "output_dir": output_dir,
            "report_name": report_name,
        }
        if len(vcf_d5) > i:
            data_dict["vcf_D5"] = vcf_d5[i]
        if len(vcf_d6) > i:
            data_dict["vcf_D6"] = vcf_d6[i]
        if len(vcf_f7) > i:
            data_dict["vcf_F7"] = vcf_f7[i]
        if len(vcf_m8) > i:
            data_dict["vcf_M8"] = vcf_m8[i]
        if bed_file:
            data_dict["bed"] = bed_file

        input_dict = {}
        for key, value in data_dict.items():
            input_dict[project_name + "." + key] = value
        inputs_file = os.path.join(output_workflow_dir, "inputs_" + str(i))
        with open(inputs_file, 'w') as fp:
            json.dump(input_dict, fp, indent=4)

        thread = threading.Thread(target=call_cromwell, args=(inputs_file, workflow_file, tasks_tarball, output_dir))
        thread.daemon = True
        thread.start()
        threads.append(thread)

    for t in threads:
        t.join()
    
    print('DNA vcf workflow and output results to %s.' % output_dir)


@omics_qc.command(help="Run the pipeline for RNA data.")
@click.option('--exp-file', required=True, multiple=False,
              type=click.Path(exists=True, file_okay=True),
              help="Expression table file.")
@click.option('--count-file', required=True, multiple=False,
              type=click.Path(exists=True, file_okay=True),
              help="Count table file.")
@click.option('--phenotype-file', required=False, multiple=False,
              type=click.Path(exists=True, file_okay=True),
              help="Phenotype file.")
@click.option('--output-dir', required=True,
              type=click.Path(exists=True, dir_okay=True),
              help="The output directory.")
def rna_qc_report(exp_file, count_file, phenotype_file, output_dir):
    report_name = "Quartet_RNA_Report.docx"
    cmd = ['Rscript', '/opt/quartet/scripts/rna_qc_report.R', phenotype_file, exp_file,
            count_file, output_dir, report_name]
    print(cmd)
    proc = Popen(cmd, stdin=PIPE)
    proc.communicate()
    print('RNA QC report is located at %s/%s.' % (output_dir, report_name))


@omics_qc.command(help="Run the pipeline for protein data.")
@click.option('--exp-file', required=True, multiple=False,
              type=click.Path(exists=True, file_okay=True),
              help="Expression table file.")
@click.option('--meta-file', required=False, multiple=False,
              type=click.Path(exists=True, file_okay=True),
              help="Metadata file.")
@click.option('--output-dir', required=True,
              type=click.Path(exists=True, dir_okay=True),
              help="The output directory.")
def protein_qc_report(exp_file, meta_file, output_dir):
    report_name = "Quartet_Protein_Report.docx"
    cmd = ['Rscript', '/opt/quartet/scripts/protein_qc_report.R', exp_file, meta_file,
            output_dir, report_name]
    proc = Popen(cmd, stdin=PIPE)
    proc.communicate()
    print('Protein QC report is located at %s/%s.' % (output_dir, report_name))


@omics_qc.command(help="Run the pipeline for metabolism data.")
@click.option('--exp-file', required=True, multiple=False,
              type=click.Path(exists=True, file_okay=True),
              help="Expression table file.")
@click.option('--meta-file', required=False, multiple=False,
              type=click.Path(exists=True, file_okay=True),
              help="Metadata file.")
@click.option('--output-dir', required=True,
              type=click.Path(exists=True, dir_okay=True),
              help="The output directory.")
def metabolism_qc_report(exp_file, meta_file, output_dir):
    report_name = "Quartet_Metabolism_Report.docx"
    cmd = ['Rscript', '/opt/quartet/scripts/metabolism_qc_report.R', exp_file, meta_file,
            output_dir, report_name]
    proc = Popen(cmd, stdin=PIPE)
    proc.communicate()
    print('Metabolism QC report is located at %s/%s.' % (output_dir, report_name))


if __name__ == '__main__':
    omics_qc()
