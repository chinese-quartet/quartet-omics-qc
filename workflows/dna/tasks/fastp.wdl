version 1.0

task fastp {

    input {
        String docker
        File fq1
        File fq2
    }
    
    # Estimate disk for FASTQs, sorted BAM, temporary sort files, and reference files.
    Int raw_disk_gb = ceil(size(fq1, "GB") + size(fq2, "GB")) * 2 + 320
    Int disk_gb = if raw_disk_gb > 1000 then 1000 else raw_disk_gb
    
    command <<<
        set -euo pipefail
        nt=$(nproc)
        
        local_work="/tmp/fastp"
        mkdir -p "$local_work"
        cp -f ~{fq1} "$local_work/read1.fq.gz"
        cp -f ~{fq2} "$local_work/read2.fq.gz"

        fastp \
            -i "$local_work/read1.fq.gz" \
            -I "$local_work/read2.fq.gz" \
            -o "$local_work/quartet_r1.clean.fastq.gz" \
            -O "$local_work/quartet_r2.clean.fastq.gz" \
            -j "$local_work/fastp.json" \
            -h "$local_work/fastp.html" \
            --thread $nt
        
        cp -f "$local_work/quartet_R1.clean.fastq.gz" quartet_R1.clean.fastq.gz
        cp -f "$local_work/quartet_R2.clean.fastq.gz" quartet_R2.clean.fastq.gz
        cp -f "$local_work/quartet.json" quartet.json
        cp -f "$local_work/quartet.html" quartet.html
    >>>

    output {
        File clean_fq1 = "quartet_R1.clean.fastq.gz"
        File clean_fq2 = "quartet_R2.clean.fastq.gz"
        File json = "quartet.json"
        File html = "quartet.html"
    }
    
    # ecs.g6.4xlarge, 16cpu 32GB
    # ecs.u1-c1m4.8xlarge, 32cpu, 128GB
    # ecs.u1-c1m2.2xlarge, 8cpu, 16GB
    # ecs.u1-c1m2.8xlarge, 32cpu, 64GB
    runtime {
        docker: docker
        instanceTypes: ["ecs.u1-c1m2.2xlarge"]
        systemDisk: 'cloud ' + disk_gb
    }
}
