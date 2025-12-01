#!/opt/venv/bin/python

import os
import re
import json
import click
import threading
from biominer_app_util.cli import render_app
from subprocess import Popen, PIPE


@click.group()
def omics_qc():
    pass


@omics_qc.command(help="Run the pipeline for DNA-Seq data.")
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
                "The file (%s) must be with suffixes of .vcf" % item)
    
    max_len = max([len(vcf_d5), len(vcf_d6), len(vcf_f7), len(vcf_m8)])
    min_len = min([len(vcf_d5), len(vcf_d6), len(vcf_f7), len(vcf_m8)])
    if (max_len - min_len) > 1:
        raise Exception(
                "The vcf files number should be 4 * x + δ(δ < 4)")

    wdl_dir = '/opt/quartet/workflows/dna'

    if not os.path.exists(wdl_dir):
        print("Cannot find the workflow, please contact the administrator.")
    
    def call_cromwell(inputs_fpath, workflow_fpath, tasks_path, workflow_root):
        executions_dir = os.path.join(workflow_root, "cromwell-executions")
        logs_dir = os.path.join(workflow_root, "cromwell-workflow-logs")
        executions_dir_option = '-Dbackend.providers.Local.config.root=' + executions_dir
        logs_dir_option = '-Dworkflow-options.workflow-log-dir=' + logs_dir
        cmd = ['java', '-Dconfig.file=/opt/cromwell/cromwell-local.conf', executions_dir_option, logs_dir_option,
               '-jar', '/opt/cromwell/cromwell.jar', 'run', workflow_fpath, "-i", inputs_fpath,
               "-p", tasks_path, "--workflow-root", workflow_root]
        proc = Popen(cmd, stdin=PIPE)
        proc.communicate()

    threads = []

    for i in range(max_len):
        project_name = "dseqc_" + str(i)
        report_name = "Quartet_DNA_Report_" + str(i) + ".docx"

        data_dict = {
            "project_name": project_name,
            "benchmarking_dir": os.path.join(reference_data_dir, "reference_datasets_v202103"),
            "ref_dir": os.path.join(reference_data_dir, "GRCh38.d1.vd1"),
            "output_dir": output_dir,
            "report_name": report_name,
            "vcf_D5": vcf_d5[i] if len(vcf_d5) > i else "",
            "vcf_D6": vcf_d6[i] if len(vcf_d6) > i else "",
            "vcf_F7": vcf_f7[i] if len(vcf_f7) > i else "",
            "vcf_M8": vcf_m8[i] if len(vcf_m8) > i else "",
        }

        if bed_file:
            data_dict["bed"] = bed_file

        # TODO: create multiple inputs instead
        output_workflow_dir = os.path.join(output_dir, "cromwell-workflows", project_name)
        os.makedirs(output_workflow_dir, exist_ok=True)
        render_app(wdl_dir, output_dir=output_workflow_dir,
            project_name=project_name, sample=data_dict)

        inputs_fpath = os.path.join(output_workflow_dir, "inputs")
        workflow_fpath = os.path.join(output_workflow_dir, "workflow.wdl")
        tasks_path = os.path.join(output_workflow_dir, "tasks.zip")

        thread = threading.Thread(target=call_cromwell, args=(inputs_fpath, workflow_fpath, tasks_path, output_dir))
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
    cmd = ['Rscript', '/opt/quartet/reporting/rna_qc_report.R', phenotype_file, exp_file,
            count_file, output_dir, report_name]
    print(cmd)
    proc = Popen(cmd, stdin=PIPE)
    proc.communicate()
    print('RNA QC report is located at %s/%s.' % (output_dir, report_name))


@omics_qc.command(help="Run the pipeline for RNA data.")
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
    cmd = ['Rscript', '/opt/quartet/reporting/protein_qc_report.R', exp_file, meta_file,
            output_dir, report_name]
    proc = Popen(cmd, stdin=PIPE)
    proc.communicate()
    print('Protein QC report is located at %s/%s.' % (output_dir, report_name))


if __name__ == '__main__':
    omics_qc()
