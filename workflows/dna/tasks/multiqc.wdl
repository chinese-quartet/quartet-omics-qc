version 1.0

task multiqc {

    input {
        String docker
        File summary
    }

    command <<<
        set -euo pipefail

        local_work="/tmp/benchmark"
        mkdir -p "$local_work"
        cp -f ~{summary} "$local_work/quartet.summary.csv"
        /opt/venv/bin/multiqc "$local_work"
        cp ./multiqc_data/multiqc_happy_data.json multiqc_happy_data.json
        /opt/venv/bin/python /opt/quartet/scripts/extract_tables.py -hap multiqc_happy_data.json
    >>>

    output {
        File variant_calling = "variants.calling.qc.txt"
    }

    # ecs.t6-c1m1.large, 2cpu, 2GB 
    runtime {
        docker: docker
        instanceTypes: ["ecs.t6-c1m1.large"]
        systemDisk: 'cloud 40'
    }
}
