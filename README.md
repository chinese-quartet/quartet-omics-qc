# Quartet Omics QC

This repo would evaluate and generate the multi-omics QC result with Quartet reference materials data.

## Usage

### DNA QC
1. Download the reference dataset zip file from https://zenodo.org/record/7800049/files/quartet-dseqc-report-reference-data-v20230404.zip?download=1
2. Unzip to get the folder of "quartet-dseqc-report" containing reference dataset raw files
3. Create a new folder. e.g. ~/dna_qc with a subfolder for the QC report, e.g. ~/dna_qc/report
4. Move the vcf files and "quartet-dseqc-report" folder to new created folder
5. Run the following command to evaluate the vcf files and the according QC report will be generated in the report folder prefixed with "Quartet_DNA_Report"
```
docker run -d -v ~/dna_qc:/data -it ghcr.io/chinese-quartet/quartet-omics-qc:latest dna-vcf-workflow --vcf-d5 /data/[d5_vcf].vcf --vcf-d6 /data/[d6_vcf].vcf --vcf-f7 /data/[f7_vcf].vcf --vcf-m8 /data/[m8_vcf].vcf -R /data/quartet-dseqc-report --output-dir /data/report
```

**PS:** param of `--vcf-d5`, `--vcf-d6`, `--vcf-f7`, `--vc-m8` can be specified multiple times. e.g.
- --vcf-d5 [d5_vcf].vcf --vcf-d6 [d6_vcf].vcf --vcf-f7 [f7_vcf].vcf --vcf-m8 [m8_vcf].vcf
    
    It would generate one report including mendelian concordance rate score(MCR)

- --vcf-d5 [d5_vcf].vcf
    
    It would generate one report without MCR calculation but with SNV and INDEL score only

- --vcf-d5 [d5_vcf].vcf --vcf-d6 [d6_vcf].vcf --vcf-f7 [f7_vcf].vcf --vcf-m8 [m8_vcf].vcf, --vcf-d5 [d5_vcf_1].vcf, --vcf-d6 [d6_vcf_1].vcf
    
    It would generate two reports, the first report would include the MCR calculation for the first four vcf files. And the second report would only have the SNV and INDEL score for the d5 and d6 vcf files


### RNA QC
1. Create a new folder. e.g. ~/rna_qc with a subfolder for the QC report, e.g. ~/rna_qc/report
2. Put the RNA expresssion table, count table and phenotype file to the new created folder
3. Run the following command to evaluate the RNA data and the according QC report will be generated in the report folder named "Quartet_RNA_Report.docx"
```
docker run --rm -v ~/rna_qc:/data -it ghcr.io/chinese-quartet/quartet-omics-qc:latest rna-qc-report --exp-file /data/[exp-file].csv --count-file /data/[count-file].csv --phenotype-file /data/[phenotype-file].csv --output-dir /data/report
```

### Protein QC
1. Create a new folder. e.g. ~/protein_qc with a subfolder for the QC report, e.g. ~/protein_qc/report
2. Put the protein expresssion table, and metadata file to the new created folder
3. Run the following command to evaluate the protein data and the according QC report will be generated in the report folder named "Quartet_Protein_Report.docx"
```
docker run --rm -v ~/protein_qc:/data -it ghcr.io/chinese-quartet/quartet-omics-qc:latest protein-qc-report --exp-file /data/[exp-file].csv --meta-file /data/[meta-file].csv --output-dir /data/report
```

### Metabolism QC
1. Create a new folder. e.g. ~/metabolism_qc with a subfolder for the QC report, e.g. ~/metabolism_qc/report
2. Put the metabolism expresssion table, and metadata file to the new created folder
3. Run the following command to evaluate the metabolism data and the according QC report will be generated in the report folder named "Quartet_Metabolism_Report.docx"
```
docker run --rm -v ~/metabolism_qc:/data -it ghcr.io/chinese-quartet/quartet-omics-qc:latest metabolism-qc-report --exp-file /data/[exp-file].csv --meta-file /data/[meta-file].csv --output-dir /data/report
```
