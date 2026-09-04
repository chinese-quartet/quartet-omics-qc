FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

ENV FC_LANG=en-US
ENV LC_CTYPE=en_US.UTF-8
RUN apt-get update && \
    apt install -y --no-install-recommends \
    locales
RUN locale-gen "en_US.UTF-8" && update-locale LC_CTYPE=en_US.UTF-8 

RUN apt install -y software-properties-common lsb-release wget
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
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
    libuv1-dev \
    pkg-config

RUN R -e "install.packages('edgeR', repos = c('https://bioc.r-universe.dev', 'https://cloud.r-project.org'))" && \
    R -e "install.packages('BiocManager')" && \
    R -e "BiocManager::install('limma')"
RUN R -e "install.packages('remotes')"

WORKDIR /opt

RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get install -y python3.9 python3.9-venv
RUN python3.9 -m venv venv && \
    /opt/venv/bin/pip install multiqc==1.9 pandas flask requests

RUN wget https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.32.1%2B1/OpenJDK11U-jdk_x64_linux_hotspot_11.0.32.1_1.tar.gz -O openjdk.tar.gz && \
    tar -zxvf openjdk.tar.gz && \
    rm openjdk.tar.gz
ENV JAVA_HOME=/opt/jdk-11.0.32.1+1
ENV PATH=$JAVA_HOME/bin:$PATH

RUN mkdir cromwell && \
    cd cromwell && \
    wget http://e-hpc-hangzhou.oss-cn-hangzhou.aliyuncs.com/softwares/ehpc-public-data/cromwell/cromwell-81-latest.jar -O cromwell.jar

RUN R -e "remotes::install_github('chinese-quartet/quartet-dna-qc-report/dnaseqc', ref='ed3203ab62633a23c40b5b58a565d503604fbbf9')"

RUN R -e "remotes::install_github('chinese-quartet/quartet-rna-qc-report/exp2qcdt', ref='fc433888052d1222e01dc94ab4bf163a090f8d07')"

RUN R -e "remotes::install_github('chinese-quartet/quartet-pro-qc-report/protqc', ref='9618ae36c58d88a9eae8d3b1811e5b9bf379d1b6')"

RUN R -e "remotes::install_github('chinese-quartet/quartet-met-qc-report/metqc', ref='bc33b8ed6e066a773fe4938edbff58ad2fd53408')"

RUN R -e "remotes::install_github('chinese-quartet/plasmix-protein-qc-report/PlasmixProtQC', ref='18a18e285848c1a0be83bba96078e32fa5fcf957')"

RUN R -e "remotes::install_github('chinese-quartet/plasmix-metabolite-qc-report/PlasmixMetQC', ref='5f0bf8bd9c5510050eacbd9cd857b2694a1c4837')"

COPY ./cromwell.conf /opt/cromwell/cromwell.conf

RUN mkdir quartet
COPY scripts /opt/quartet/scripts
COPY workflows /opt/quartet/workflows

COPY omics_qc.py /opt/quartet/omics_qc.py
COPY fc.py /opt/quartet/fc.py

ENTRYPOINT ["/opt/quartet/omics_qc.py"]
