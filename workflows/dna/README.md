# Quality control pipeline of germline variants calling

This Quartet quality control pipeline evaluate the performance of reads quality and variant calling quality. It accepts FASTQ format input files or VCF format input files.

If the input is FASTQ files, it would first process the FASTQ files to VCF files with the following steps:

- Pre-alignment QC of FASTQ files
- Genome alignment
- Mark duplicates
- Post-alignment QC of BAM files
- Germline variant calling 

Afterwards it would evaluate the VCF files and mendelian concordance rate:
- Variant calling QC depended on benchmark sets of VCF files
- Check Mendelian ingeritance states across four Quartet samples of every variants


## Data Processing Steps

1. Pre-alignment QC of FASTQ files

    [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) is used to investigate the quality of fastq files

    [Fastq Screen](<https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/>) is used to inspect whether the library were contaminated. For example, we expected 99% reads aligned to human genome, 10% reads aligned to mouse genome, which is partly homologous to human genome. If too many reads are aligned to E.Coli or Yeast, libraries or cell lines are probably comtminated.

2. Genome alignment

    Reads were mapped to the human reference genome GRCh38 using [BWA-MEM](https://github.com/lh3/bwa). And sorted with [SAMTools](https://github.com/samtools/samtools)

3. Mark duplicates

    Use `MarkDuplicates` in [Picard](https://github.com/broadinstitute/picard) toolsets to identifies duplicate reads. And build an index for the sorted and deduplicated bam file.

4. Post-alignment QC

    [Qualimap](http://qualimap.bioinfo.cipf.es/) is used to check the quality of BAM files.

5. Germline variant calling

    [Google DeepVariant](https://github.com/google/deepvariant) is used to identify germline variants.


6. Variants Calling QC

    a) Performance assessment based on benchmark sets


    Variants were compared with benchmark calls in benchmark regions with [Hap.py](<https://github.com/Illumina/hap.py>).

    ```bash
    hap.py <truth_vcf> <query_vcf> -f <bed_file> --threads <threads> -o <output_filename>
    ```

    b) Performance assessment based on Quartet genetic built-in truth

    We splited the Quartet family to two trios (F7, M8, D5 and F7, M8, D6) and then do the Mendelian analysis with [VBT](https://github.com/sbg/VBT-TrioAnalysis). A Quartet Mendelian concordant variant is the same between the twins (D5 and D6), and follow the Mendelian concordant between parents (F7 and M8). Mendelian concordance rate is the Mendelian concordance variant divided by total detected variants in a Quartet family. Only variants on chr1-22, X are included in this analysis.
