version 1.0

task fastdup {

    input {
        String docker
        File bam
    }
    
    # Estimate disk for BAM input, Spark shuffle, and output BAM.
    Int raw_disk_gb = ceil(size(bam, "GB") * 4) + 420
    Int disk_gb = if raw_disk_gb > 1000 then 1000 else raw_disk_gb
    
    command <<<
        set -euo pipefail
        nt=$(nproc)
        
        local_work="/tmp/dedup"
        mkdir -p "$local_work"

        cp -f ~{bam} "$local_work/raw.bam"

        fastdup \
            --input "$local_work/raw.bam" \
            --output "$local_work/quartet.dedup.bam" \
            --metrics "$local_work/quartet.metrics.txt" \
            --num-threads $nt

        cp -f "$local_work/quartet.dedup.bam" quartet.dedup.bam
        cp -f "$local_work/quartet.metrics.txt" quartet.metrics.txt
    >>>

    output {
        File dedup_bam = "quartet.dedup.bam"
        File metrics = "quartet.metrics.txt"
    }

    # ecs.u1-c1m2.8xlarge, 32cpu, 64GB
    runtime {
        docker: docker
        instanceTypes: ["ecs.u1-c1m2.8xlarge"]
        systemDisk: 'cloud ' + disk_gb
    }
}
