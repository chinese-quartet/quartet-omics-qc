#!/opt/venv/bin/python

from flask import Flask
from flask import request
import json
import os
import oss2
import requests
from subprocess import Popen, PIPE
import time

REQUEST_ID_HEADER = 'x-fc-request-id'
REQUEST_INVOCATION_TYPE = 'X-Fc-Invocation-Type'

DNA_ITEM_ID = 'omics-dna-id'
DNA_ITEM_VCF = 'omics-dna-vcf'
DNA_ITEM_FAMILY_MEMBER = 'omics-dna-family-member'

app = Flask(__name__)


@app.route('/', defaults={'path': ''})
@app.route('/<path:path>', methods=['POST'])
def hello_world(path):
    rid = request.headers.get(REQUEST_ID_HEADER)
    rit = request.headers.get(REQUEST_INVOCATION_TYPE)
    dii = int(request.headers.get(DNA_ITEM_ID))
    div = request.headers.get(DNA_ITEM_VCF)
    dif = int(request.headers.get(DNA_ITEM_FAMILY_MEMBER))

    data = request.stream.read()
    print("Path: " + path)
    print("Data: " + str(data))
    print(rid)
    print(rit)
    print(dii)
    print(div)
    print(dif)

    workflow_file = "/opt/quartet/workflows/dna/workflow.wdl"
    ## tasks.zip is the zipped tarball of tasks folder and will be auto generated in dockerfile
    tasks_tarball = "/opt/quartet/workflows/dna/tasks.zip"

    project_name = "dseqc"
    report_name = "Quartet_DNA_Report.docx"
    qc_file = "variants.calling.qc.txt"
    reference_data_dir = "/opt/quartet-dseqc-report-reference-data"

    output_dir = os.path.join("/tmp/omics-portal", f'{time.monotonic_ns()}')
    output_workflow_dir = os.path.join(output_dir, "cromwell-workflows", project_name)
    os.makedirs(output_workflow_dir, exist_ok=True)

    endpoint = os.getenv('ALIYUN_OSS_ENDPOINT')
    auth = oss2.Auth(os.getenv('ALIYUN_ACCESS_KEY_ID'), os.getenv('ALIYUN_ACCESS_KEY_SECRET'))
    bucket = oss2.Bucket(auth, endpoint, os.getenv('ALIYUN_OSS_BUCKET'))
    # div: dna/1767661472131_Sample_01_final.vcf
    file_name = div.split('/')
    file_name = file_name[-1]
    file_name = file_name.split("_", 1)
    file_name = file_name[-1]
    local_file_path = os.path.join(output_dir, file_name)
    result = bucket.get_object_to_file(div, local_file_path)
    print(f"File '{div}' downloaded successfully to '{local_file_path}'.")
    
    quartet_ref_dir = os.path.join(reference_data_dir, "reference_datasets_v202103")
    quartet_d5_hc_vcf = os.path.join(quartet_ref_dir, "LCL5.high.confidence.calls.vcf")
    quartet_d6_hc_vcf = os.path.join(quartet_ref_dir, "LCL6.high.confidence.calls.vcf")
    quartet_f7_hc_vcf = os.path.join(quartet_ref_dir, "LCL7.high.confidence.calls.vcf")
    quartet_m8_hc_vcf = os.path.join(quartet_ref_dir, "LCL8.high.confidence.calls.vcf")
    quartet_hc_region = os.path.join(quartet_ref_dir, "Quartet.high.confidence.region.v202103.bed")
    grc_ref_fa = os.path.join(reference_data_dir, "GRCh38.d1.vd1", "GRCh38.d1.vd1.fa")

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
        "qc_file": qc_file,
    }
    if dif == 5:
        data_dict["vcf_D5"] = local_file_path
    if dif == 6:
        data_dict["vcf_D6"] = local_file_path
    if dif == 7:
        data_dict["vcf_F7"] = local_file_path
    if dif == 8:
        data_dict["vcf_M8"] = local_file_path
    # if bed_file:
    #     data_dict["bed"] = bed_file

    input_dict = {}
    for key, value in data_dict.items():
        input_dict[project_name + "." + key] = value
    inputs_file = os.path.join(output_workflow_dir, "inputs")
    with open(inputs_file, 'w') as fp:
        json.dump(input_dict, fp, indent=4)

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

    call_cromwell(inputs_file, workflow_file, tasks_tarball, output_dir)
    print('DNA vcf workflow and output results to %s.' % output_dir)

    variants_qc_file = os.path.join(output_dir, qc_file)

    url = os.getenv('OMICS_PORTAL_URL')
    auth_payload = {
        "email": os.getenv('OMICS_PORTAL_EMAIL'),
        "password": os.getenv('OMICS_PORTAL_PASSWORD'),
    }
    if not os.path.isfile(variants_qc_file):
        with requests.Session() as s:
            response = s.post(f'{url}/api/auth/token', json=auth_payload)

            print(f"Login status Code: {response.status_code}")

            score_payload = {
                "notes": "auditing"
            }
            response = s.put(f'{url}/api/admin/omics/quartet/dna/{dii}/score', json=score_payload)
            response_json = response.json()
            print(f"Update notes status Code: {response.status_code}")
            print(response_json)
        return "Error", 200, [('Function-Name', os.getenv('FC_FUNCTION_NAME'))]

    with open(variants_qc_file, 'r') as file:
        lines = file.readlines()

    data = lines[1].rstrip()
    result = data.split('\t')

    name = result[0]
    snv_number = result[1]
    indel_number = result[2]
    snv_precision = result[3]
    indel_precision = result[4]
    snv_recall = result[5]
    indel_recall = result[6]

    with requests.Session() as s:
        response = s.post(f'{url}/api/auth/token', json=auth_payload)

        print(f"Login status Code: {response.status_code}")

        score_payload = {
            "snv_number": int(snv_number),
            "indel_number": int(indel_number),
            "snv_precision": float(snv_precision),
            "indel_precision": float(indel_precision),
            "snv_recall": float(snv_recall),
            "indel_recall": float(indel_recall),
        }
        response = s.put(f'{url}/api/admin/omics/quartet/dna/{dii}/score', json=score_payload)
        response_json = response.json()
        print(f"Update score status Code: {response.status_code}")
        print(response_json)
    
    return "Success", 200, [('Function-Name', os.getenv('FC_FUNCTION_NAME'))]


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9000)
