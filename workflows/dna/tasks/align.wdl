version 1.0

task align {

    input {
        String docker
        File fq1
        File fq2
        File ref
    }
    
    # Estimate disk for FASTQs, sorted BAM, temporary sort files, and reference files.
    Int raw_disk_gb = ceil(size(fq1, "GB") + size(fq2, "GB")) * 2 + 320
    Int disk_gb = if raw_disk_gb > 1000 then 1000 else raw_disk_gb

    command <<<
        set -euo pipefail
        nt=$(nproc)
        
        local_work="/tmp/mapping"
        mkdir -p "$local_work"
        cp -f ~{fq1} "$local_work/read1.fq.gz"
        cp -f ~{fq2} "$local_work/read2.fq.gz"
        
        bwa-mem2 mem \
            -K 100000000 \
            -t $nt \
            -R "@RG\tID:quartet\tSM:quartet" \
            ~{ref} \
            "$local_work/read1.fq.gz" \
            "$local_work/read2.fq.gz" | \
        samtools sort \
            -@ $nt \
            -m 2G \
            -T "$local_work/quartet.sorttmp" \
            -o "$local_work/quartet.sorted.bam"
        
        cp -f "$local_work/quartet.sorted.bam" quartet.sorted.bam
    >>>

    output {
        File sorted_bam = "quartet.sorted.bam"
    }
    
    # ecs.u1-c1m2.8xlarge, 32cpu, 64GB
    runtime {
        docker: docker
        instanceTypes: ["ecs.u1-c1m2.8xlarge"]
        systemDisk: 'cloud ' + disk_gb
    }
}
