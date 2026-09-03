#!/opt/venv/bin/python

import click
from subprocess import Popen, PIPE


@click.group()
def omics_qc():
    pass


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
