version 1.0

task filter {

    input {
        String docker
        File norm_vcf
    }

    command <<<
        set -euo pipefail

        bcftools view \
            -f .,PASS \
            -Oz \
            -o pass.vcf.gz \
            ~{norm_vcf}

        bcftools view \
            -i 'GT!="0/0" && GT!="./."' \
            pass.vcf.gz \
            > quartet.filter.vcf
    >>>

    output {
        File filter_vcf = "quartet.filter.vcf"
    }

    # ecs.u1-c1m2.2xlarge, 8cpu, 16GB
    runtime {
        docker: docker
        instanceTypes: ["ecs.u1-c1m2.2xlarge"]
        systemDisk: 'cloud 40'
    }
}

task vcffilter {

    input {
        String docker
        File vcf
    }
    
    command <<<
        local_work="/tmp/filter"
        mkdir -p "$local_work"

        if [[ ~{vcf} == *.gz ]]; then
            cp -f ~{vcf} "$local_work/quartet.vcf.gz"
            gunzip -c "$local_work/quartet.vcf.gz" > "$local_work/quartet.vcf"
        else
            cp -f ~{vcf} "$local_work/quartet.vcf"
        fi
        cat "$local_work/quartet.vcf" | grep '#' > "$local_work/header"
        cat "$local_work/quartet.vcf" | grep -v '#' > "$local_work/body"
        cat "$local_work/body" | grep -w '^chr1\|^chr2\|^chr3\|^chr4\|^chr5\|^chr6\|^chr7\|^chr8\|^chr9\|^chr10\|^chr11\|^chr12\|^chr13\|^chr14\|^chr15\|^chr16\|^chr17\|^chr18\|^chr19\|^chr20\|^chr21\|^chr22\|^chrX' > "$local_work/body.filtered"
        cat "$local_work/header" "$local_work/body.filtered" > "$local_work/quartet.filtered.vcf"
        cp -f "$local_work/quartet.filtered.vcf" quartet.filtered.vcf
    >>>

	output {
		File filter_vcf = "quartet.filtered.vcf"
	}

    runtime {
        docker: docker
        instanceTypes: ["ecs.u1-c1m2.2xlarge"]
        systemDisk: 'cloud 40'
    }
}
