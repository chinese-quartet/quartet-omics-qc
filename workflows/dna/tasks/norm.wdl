version 1.0

task vcfnorm {

    input {
        String docker
        File raw_vcf
        File ref 
    }

    command <<<
        set -euo pipefail

        bcftools norm \
            -f ~{ref} \
            -Oz \
            -o quartet.norm.vcf.gz \
            ~{raw_vcf}
    >>>

    output {
        File norm_vcf = "quartet.norm.vcf.gz"
    }
    
    # ecs.u1-c1m2.2xlarge, 8cpu, 16GB
    runtime {
        docker: docker
        instanceTypes: ["ecs.u1-c1m2.2xlarge"]
        systemDisk: 'cloud 40'
    }
}
