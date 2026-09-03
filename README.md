# Quartet Omics QC

This repo would evaluate and generate the multi-omics QC result with Quartet reference materials data.

## Usage

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
