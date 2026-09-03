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
DNA_ITEM_FQR1 = 'omics-dna-fqr1'
DNA_ITEM_FQR2 = 'omics-dna-fqr2'
DNA_ITEM_MODE = 'omics-dna-mode'
DNA_ITEM_FAMILY_MEMBER = 'omics-dna-family-member'

app = Flask(__name__)


@app.route('/', defaults={'path': ''})
@app.route('/<path:path>', methods=['POST'])
def hello_world(path):
    rid = request.headers.get(REQUEST_ID_HEADER)
    rit = request.headers.get(REQUEST_INVOCATION_TYPE)
    dii = int(request.headers.get(DNA_ITEM_ID))
    div = request.headers.get(DNA_ITEM_VCF)
    dif1 = request.headers.get(DNA_ITEM_FQR1)
    dif2 = request.headers.get(DNA_ITEM_FQR2)
    dif = int(request.headers.get(DNA_ITEM_FAMILY_MEMBER))
    dim = int(request.headers.get(DNA_ITEM_MODE))

    data = request.stream.read()
    print("Path: " + path)
    print("Data: " + str(data))
    print(rid)
    print(rit)
    print(dii)
    print(div)
    print(dif1)
    print(dif2)
    print(dif)
    print(dim)

    aliyun_access_key_id = os.getenv('ALIYUN_ACCESS_KEY_ID')
    aliyun_access_key_secret = os.getenv('ALIYUN_ACCESS_KEY_SECRET')
    aliyun_region = os.getenv('ALIYUN_REGION')
    aliyun_oss_bucket = os.getenv('ALIYUN_OSS_BUCKET')

    workflow_name = "QuartetDNAPipeline"
    qc_file = "variants.calling.qc.txt"

    output_dir = os.path.join("/tmp/omics-portal", f'{time.monotonic_ns()}')
    os.makedirs(output_dir, exist_ok=True)

    data_dict = {
        "ref": os.getenv('HGREF_FA'),
        "sdf_template": os.getenv('HGREF_SDF'),
        "truth_d5_vcf": os.getenv('QUARTET_REF_D5'),
        "truth_d6_vcf": os.getenv('QUARTET_REF_D6'),
        "truth_f7_vcf": os.getenv('QUARTET_REF_F7'),
        "truth_m8_vcf": os.getenv('QUARTET_REF_M8'),
        "truth_bed": os.getenv('QUARTET_REF_BED'),
        "docker_fastp": os.getenv('DOCKER_FASTP'),
        "docker_bwa": os.getenv('DOCKER_BWA'),
        "docker_fastdup": os.getenv('DOCKER_FASTUP'),
        "docker_strelka": os.getenv('DOCKER_STRELKA'),
        "docker_happy": os.getenv('DOCKER_HAPPY'),
        "docker_bcftools": os.getenv('DOCKER_BCFTOOLS'),
        "docker_multiqc": os.getenv('DOCKER_MULTIQC'),
    }

    if dim == "vcf":
        data_dict["vcf"] = f'oss://{aliyun_oss_bucket}/{div}'
    else:
        data_dict["fastq_r1"] = f'oss://{aliyun_oss_bucket}/{dif1}'
        data_dict["fastq_r2"] = f'oss://{aliyun_oss_bucket}/{dif2}'

    if dif == 5:
        data_dict["member"] = "D5"
    if dif == 6:
        data_dict["member"] = "D6"
    if dif == 7:
        data_dict["member"] = "F7"
    if dif == 8:
        data_dict["member"] = "M8"

    input_dict = {}
    for key, value in data_dict.items():
        input_dict[workflow_name + "." + key] = value
    input_file = os.path.join(output_dir, "inputs.json")
    with open(input_file, 'w') as fp:
        json.dump(input_dict, fp, indent=4)

    option_dict = {
        "final_workflow_outputs_dir": output_dir,
    }
    option_file = os.path.join(output_dir, "options.json")
    with open(option_file, 'w') as fp:
        json.dump(option_dict, fp, indent=4)

    def call_cromwell(input_file, option_file):
        cmd = ['java', '-Dconfig.file=/opt/cromwell/cromwell.conf',
               f'-Dengine.filesystems.oss.auth.endpoint=oss-{aliyun_region}-internal.aliyuncs.com',
               f'-Dengine.filesystems.oss.auth.access-id={aliyun_access_key_id}',
               f'-Dengine.filesystems.oss.auth.access-key={aliyun_access_key_secret}',
               f'-Dbackend.providers.EHPC.config.root=oss://{aliyun_oss_bucket}/',
               f'-Dbackend.providers.EHPC.config.region={aliyun_region}',
               f'-Dbackend.providers.EHPC.config.domain=ehpcinstant.{aliyun_region}.aliyuncs.com',
               f'-Dbackend.providers.EHPC.config.access-id={aliyun_access_key_id}',
               f'-Dbackend.providers.EHPC.config.access-key={aliyun_access_key_secret}',
               f'-Dbackend.providers.EHPC.config.filesystems.oss.bucket={aliyun_oss_bucket}',
               f'-Dbackend.providers.EHPC.config.filesystems.oss.auth.endpoint=oss-{aliyun_region}-internal.aliyuncs.com',
               f'-Dbackend.providers.EHPC.config.filesystems.oss.auth.access-id={aliyun_access_key_id}',
               f'-Dbackend.providers.EHPC.config.filesystems.oss.auth.access-key={aliyun_access_key_secret}',
               '-jar', '/opt/cromwell/cromwell.jar', 'run', '/opt/quartet/workflows/dna/workflow.wdl',
               "-i", input_file,
               "-o", option_file]
        proc = Popen(cmd, stdin=PIPE)
        proc.communicate()

    call_cromwell(input_file, option_file)
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
