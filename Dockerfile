FROM ubuntu:20.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        autoconf \
        build-essential \
        bzip2 \
        cmake \
        git \
        libbz2-dev \
        libncurses5-dev \
        liblzma-dev \
        openjdk-8-jdk \
        pkg-config \
        python2 \
        python2-dev \
        software-properties-common \
        wget \
        zlib1g-dev

WORKDIR /opt
# build hap.py by refering to https://github.com/Illumina/hap.py/blob/master/Dockerfile
RUN git clone --branch v0.3.15 https://github.com/Illumina/hap.py.git hap.py-source
RUN mkdir -p /opt/hap.py-data

RUN wget http://archive.apache.org/dist/ant/binaries/apache-ant-1.9.7-bin.tar.gz && \
    tar xzf apache-ant-1.9.7-bin.tar.gz && \
    rm apache-ant-1.9.7-bin.tar.gz
ENV PATH=$PATH:/opt/apache-ant-1.9.7/bin

WORKDIR /opt/hap.py-source
RUN python2 install.py /opt/hap.py --with-rtgtools --no-tests

WORKDIR /opt/hap.py
RUN bin/test_haplotypes

## build vbt by refering to https://github.com/sbg/VBT-TrioAnalysis?tab=readme-ov-file#installing-vbt
WORKDIR /opt
RUN wget https://github.com/samtools/htslib/releases/download/1.22.1/htslib-1.22.1.tar.bz2
RUN tar xvjf htslib-1.22.1.tar.bz2
WORKDIR /opt/htslib-1.22.1
RUN ./configure
RUN make install

WORKDIR /opt
RUN git clone https://github.com/sbg/VBT-TrioAnalysis.git vbt
WORKDIR /opt/vbt
RUN cp -R /opt/htslib-1.22.1/htslib /opt/vbt/
RUN cp /opt/htslib-1.22.1/libhts.a /opt/vbt/lib/
RUN cp /opt/htslib-1.22.1/libhts.so /opt/vbt/lib/
RUN cp /opt/htslib-1.22.1/libhts.so.3 /opt/vbt/lib/
RUN make all

WORKDIR /opt
RUN git clone -b v0.7.19 https://github.com/lh3/bwa.git
WORKDIR /opt/bwa
RUN make

WORKDIR /opt
RUN wget https://github.com/samtools/samtools/releases/download/1.22.1/samtools-1.22.1.tar.bz2
RUN tar -xjvf samtools-1.22.1.tar.bz2
WORKDIR /opt/samtools-1.22.1
RUN ./configure --prefix=/opt/samtools
RUN make
RUN make install

RUN apt-get install -y unzip
WORKDIR /opt
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.12.1.zip
RUN unzip fastqc_v0.12.1.zip

RUN wget https://github.com/StevenWingett/FastQ-Screen/archive/refs/tags/v0.16.0.tar.gz
RUN tar -zxvf v0.16.0.tar.gz

RUN wget https://bitbucket.org/kokonech/qualimap/downloads/qualimap_v2.3.zip
# COPY ./qualimap_v2.3.zip .
RUN unzip qualimap_v2.3.zip

RUN mkdir -p /opt/picard && \
    cd /opt/picard && \
    wget https://github.com/broadinstitute/picard/releases/download/3.4.0/picard.jar

RUN wget https://twds.dl.sourceforge.net/project/bowtie-bio/bowtie2/2.5.4/bowtie2-2.5.4-linux-x86_64.zip
RUN unzip bowtie2-2.5.4-linux-x86_64.zip


FROM google/deepvariant:1.9.0 AS runner

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    build-essential \
    git \
    libbz2-dev \
    libncurses5-dev \
    liblzma-dev \
    python2 \
    python2-dev \
    wget \
    zlib1g-dev

# for hap.py(https://github.com/Illumina/hap.py) with rtg tools
RUN wget https://bootstrap.pypa.io/pip/2.7/get-pip.py && \
    python2 get-pip.py && \
    pip2 install setuptools psutil numpy pandas distribute pysam scipy bx-python

WORKDIR /opt
COPY --from=builder /opt/apache-ant-1.9.7 /opt/apache-ant-1.9.7
ENV PATH=$PATH:/opt/apache-ant-1.9.7/bin

COPY --from=builder /opt/hap.py /opt/hap.py
ENV PATH=/opt/hap.py/bin:/opt/hap.py/libexec/rtg-tools-install/:$PATH

# cromwell 89 would require java 17
RUN mkdir cromwell && \
    cd cromwell && \
    wget https://github.com/broadinstitute/cromwell/releases/download/89/cromwell-89.jar -O cromwell.jar
COPY ./cromwell-local.conf /opt/cromwell/cromwell-local.conf
# TODO
# cromwell 91
# [2025-11-10 02:20:40,26] [error] Timed out trying to gracefully stop WorkflowManagerActor. Forcefully stopping it.
# [2025-11-10 02:20:40,26] [warn] Coordinated shutdown phase [abort-all-workflows] timed out after 3600000 milliseconds
# [2025-11-10 02:20:40,26] [warn] Task [stopWorkflowManagerActor] failed in phase [abort-all-workflows]: Ask timed out on [Actor[akka://cromwell-system/user/SingleWorkflowRunnerActor/WorkflowManagerActor#-1814082012]] after [3600000 ms]. Message of type [cromwell.engine.workflow.WorkflowManagerActor$AbortAllWorkflowsCommand$]. A typical reason for AskTimeoutException is that the recipient actor didn't send a reply.

RUN wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.17%2B10/OpenJDK17U-jdk_x64_linux_hotspot_17.0.17_10.tar.gz -O openjdk.tar.gz && \
    tar -zxvf openjdk.tar.gz && \
    rm openjdk.tar.gz
ENV JAVA_HOME=/opt/jdk-17.0.17+10
ENV PATH=$JAVA_HOME/bin:$PATH

COPY --from=builder /opt/vbt /opt/vbt
RUN cp /opt/vbt/lib/libhts.so.3 /lib/x86_64-linux-gnu
ENV PATH=/opt/vbt:$PATH

RUN wget https://github.com/arq5x/bedtools2/releases/download/v2.31.0/bedtools.static -O bedtools && \
    chmod +x bedtools && \
    mv bedtools /usr/local/sbin/

ENV PYTHONDONTWRITEBYTECODE=1
ENV FC_LANG=en-US
ENV LC_CTYPE=en_US.UTF-8
RUN apt-get update && \
    apt install -y --no-install-recommends \
    locales
RUN locale-gen "en_US.UTF-8" && update-locale LC_CTYPE=en_US.UTF-8 

RUN apt install -y software-properties-common lsb-release && \
    wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && \
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
RUN apt install -y --no-install-recommends \
    r-base \
    cmake \
    gfortran \
    libblas-dev \
    libcurl4-openssl-dev \
    libfreetype6-dev \
    libfribidi-dev \
    libharfbuzz-dev \
    libjpeg-dev \
    liblapack-dev \
    libmagick++-dev \
    libpng-dev \
    libpoppler-cpp-dev \
    librsvg2-dev \
    libssl-dev \
    libtiff5-dev \
    libwebp-dev \
    libxml2-dev \
    libxslt1-dev \
    pkg-config

RUN R -e "install.packages('remotes')"
RUN R -e "remotes::install_github('chinese-quartet/Quartet-DNA-QC-report/dnaseqc', ref='master')"

RUN R -e "install.packages('edgeR', repos = c('https://bioc.r-universe.dev', 'https://cloud.r-project.org'))" && \
    R -e "install.packages('BiocManager')" && \
    R -e "BiocManager::install('limma')" && \
    R -e "remotes::install_github('chinese-quartet/Quartet-RNA-QC-report/exp2qcdt', ref='main')"

RUN R -e "remotes::install_github('chinese-quartet/Quartet-Protein-QC/protqc', ref='main')"

RUN R -e "remotes::install_github('chinese-quartet/Quartet-Metabolism-QC-Report/metqc', ref='main')"

RUN apt-get install -y python3.10 python3.10-venv
# multiqc needs to be 1.9 for the DNA workflow compatibility
RUN python3.10 -m venv venv && \
    /opt/venv/bin/pip install multiqc==1.9

COPY --from=builder /opt/bwa/bwa /usr/local/sbin
COPY --from=builder /opt/samtools /opt/samtools
COPY --from=builder /opt/FastQC /opt/FastQC
# for fastq-screen
RUN apt-get install -y libgd-dev libgd-graph-perl
COPY --from=builder /opt/bowtie2-2.5.4-linux-x86_64 /opt/bowtie2
COPY --from=builder /opt/FastQ-Screen-0.16.0 /opt/FastQ-Screen
COPY --from=builder /opt/qualimap_v2.3 /opt/qualimap
## Fix compatibility issue with jdk17
RUN sed -i '42s/MaxPermSize/MaxMetaspaceSize/' /opt/qualimap/qualimap
COPY --from=builder /opt/picard /opt/picard
ENV PATH=/opt/qualimap:/opt/FastQ-Screen:/opt/FastQC:/opt/bowtie2:/opt/samtools/bin:$PATH

RUN mkdir quartet
COPY workflows /opt/quartet/workflows
RUN cd /opt/quartet/workflows/dna/ && \
    zip -r tasks.zip tasks/
COPY scripts /opt/quartet/scripts
COPY omics_qc.py /opt/quartet/omics_qc.py
ENTRYPOINT ["/opt/quartet/omics_qc.py"]
