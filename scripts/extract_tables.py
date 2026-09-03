import json
import pandas as pd
import argparse

parser = argparse.ArgumentParser(description="This script is to get information from multiqc and sentieon, output the raw fastq, bam and variants calling (precision and recall) quality metrics")

parser.add_argument('-hap', '--happy', type=str, help='multiqc_happy_data.json',  required=True)

args = parser.parse_args()

hap_file = args.happy
with open(hap_file) as hap_json:
	happy = json.load(hap_json)
dat =pd.DataFrame.from_records(happy)
dat = dat.loc[:, dat.columns.str.endswith('ALL')]
dat_transposed = dat.T
dat_transposed = dat_transposed.loc[:,['sample_id','QUERY.TOTAL','METRIC.Precision','METRIC.Recall']]
indel = dat_transposed[['INDEL_ALL' in s for s in dat_transposed.index]]
snv = dat_transposed[['SNP_ALL' in s for s in dat_transposed.index]]
indel.reset_index(drop=True, inplace=True)
snv.reset_index(drop=True, inplace=True)
benchmark = pd.concat([snv, indel], axis=1)
benchmark = benchmark[["sample_id", 'QUERY.TOTAL', 'METRIC.Precision', 'METRIC.Recall']]
benchmark.columns = ['Sample','sample_id','SNV number','INDEL number','SNV precision','INDEL precision','SNV recall','INDEL recall']
benchmark = benchmark[['Sample','SNV number','INDEL number','SNV precision','INDEL precision','SNV recall','INDEL recall']]
benchmark['SNV precision'] = benchmark['SNV precision'].astype(float)
benchmark['INDEL precision'] = benchmark['INDEL precision'].astype(float)
benchmark['SNV recall'] = benchmark['SNV recall'].astype(float)
benchmark['INDEL recall'] = benchmark['INDEL recall'].astype(float)
benchmark['SNV precision'] = benchmark['SNV precision'] * 100
benchmark['INDEL precision'] = benchmark['INDEL precision'] * 100
benchmark['SNV recall'] = benchmark['SNV recall'] * 100
benchmark['INDEL recall'] = benchmark['INDEL recall']* 100
benchmark = benchmark.round(2)
benchmark.to_csv('variants.calling.qc.txt',sep="\t",index=0)
