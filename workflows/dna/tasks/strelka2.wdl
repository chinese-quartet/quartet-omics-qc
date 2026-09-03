version 1.0

task strelka {

    input {
        String docker
        File bam
        File ref
    }
    
    # Estimate disk for BAM input, Spark shuffle, and output BAM.
    Int raw_disk_gb = ceil(size(bam, "GB") * 4) + 420
    Int disk_gb = if raw_disk_gb > 1000 then 1000 else raw_disk_gb
    
    command <<<
        set -euo pipefail
        nt=$(nproc)
        
        local_work="/tmp/strelka"
        mkdir -p "$local_work"

        cp -f ~{bam} "$local_work/raw.bam"

        samtools index -@ 32 "$local_work/raw.bam"

        /usr/local/bin/configureStrelkaGermlineWorkflow.py \
            --bam "$local_work/raw.bam" \
            --referenceFasta ~{ref} \
            --runDir "$local_work/strelka_run"

        "$local_work/strelka_run"/runWorkflow.py \
            -m local \
            -j $nt
         
        cp -f "$local_work/strelka_run/results/variants/variants.vcf.gz" variants.vcf.gz
    >>>

    output {
        File raw_vcf = "variants.vcf.gz"
    }

    # ecs.u1-c1m2.8xlarge, 32cpu, 64GB
    runtime {
        docker: docker
        instanceTypes: ["ecs.u1-c1m2.8xlarge"]
        systemDisk: 'cloud ' + disk_gb
    }
}
