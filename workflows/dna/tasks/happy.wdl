version 1.0

task happy {

    input {
        String docker
        
        String member
        File query_vcf

        File truth_d5_vcf
        File truth_d6_vcf
        File truth_f7_vcf
        File truth_m8_vcf
        File truth_bed

        File ref
        File sdf_template
    }

    command <<<
        set -euo pipefail

        if [[ ~{member} == "D5" ]];then
            /opt/hap.py/bin/hap.py \
                ~{truth_d5_vcf} \
                ~{query_vcf} \
                --threads 10 \
                -r ~{ref} \
                -f ~{truth_bed} \
                --engine vcfeval \
                --engine-vcfeval-template ~{sdf_template} \
                -o happy
        elif [[ ~{member} == "D6" ]]; then
            /opt/hap.py/bin/hap.py \
                ~{truth_d5_vcf} \
                ~{query_vcf} \
                --threads 10 \
                -r ~{ref} \
                -f ~{truth_bed} \
                --engine vcfeval \
                --engine-vcfeval-template ~{sdf_template} \
                -o happy
        elif [[ ~{member} == "F7" ]]; then
            /opt/hap.py/bin/hap.py \
                ~{truth_f7_vcf} \
                ~{query_vcf} \
                --threads 10 \
                -r ~{ref} \
                -f ~{truth_bed} \
                --engine vcfeval \
                --engine-vcfeval-template ~{sdf_template} \
                -o happy
        elif [[ ~{member} == "M8" ]]; then
            /opt/hap.py/bin/hap.py \
                ~{truth_m8_vcf} \
                ~{query_vcf} \
                --threads 10 \
                -r ~{ref} \
                -f ~{truth_bed} \
                --engine vcfeval \
                --engine-vcfeval-template ~{sdf_template} \
                -o happy
        else
            echo "only for quartet samples"
        fi
    >>>

    output {
        File summary = "happy.summary.csv"
    }

    # ecs.u1-c1m2.8xlarge, 32cpu, 64GB
    runtime {
        docker: docker
        instanceTypes: ["ecs.u1-c1m2.8xlarge"]
        systemDisk: 'cloud 40'
    }
}
