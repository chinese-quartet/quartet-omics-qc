FROM ubuntu:24.04 AS runner

ENV DEBIAN_FRONTEND=noninteractive

ENV FC_LANG=en-US
ENV LC_CTYPE=en_US.UTF-8
RUN apt-get update && \
    apt install -y --no-install-recommends \
    locales
RUN locale-gen "en_US.UTF-8" && update-locale LC_CTYPE=en_US.UTF-8 

RUN apt install -y software-properties-common lsb-release
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
    pkg-config

RUN R -e "install.packages('edgeR', repos = c('https://bioc.r-universe.dev', 'https://cloud.r-project.org'))" && \
    R -e "install.packages('BiocManager')" && \
    R -e "BiocManager::install('limma')"

RUN R -e "install.packages('remotes')"
RUN R -e "remotes::install_github('chinese-quartet/Quartet-DNA-QC-report/dnaseqc', ref='68985009a8173ab50823de948fc050c31abc4e94')"

RUN R -e "remotes::install_github('chinese-quartet/Quartet-RNA-QC-report/exp2qcdt', ref='f5105f3953db250a1323683736cb891c03610a9e')"

RUN R -e "remotes::install_github('chinese-quartet/Quartet-Protein-QC/protqc', ref='af4bd8bce8ad8ee7e528efeebb6812519e4119ce')"

RUN R -e "remotes::install_github('chinese-quartet/Quartet-Metabolism-QC-Report/metqc', ref='5ed3ceed713ff10cb1426305fdbcdc899180aa0f')"

RUN R -e "remotes::install_github('chinese-quartet/Plasmix-Protein-QC-Report/PlasmixProtQC', ref='18a18e285848c1a0be83bba96078e32fa5fcf957')"

RUN R -e "remotes::install_github('chinese-quartet/Plasmix-Metabolite-QC-Report/PlasmixMetQC', ref='5f0bf8bd9c5510050eacbd9cd857b2694a1c4837')"

WORKDIR /opt

RUN add-apt-repository --remove "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get install -y python3.9 python3.9-venv wget
RUN python3.9 -m venv venv && \
    /opt/venv/bin/pip install multiqc==1.9 pandas

RUN wget https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.32.1%2B1/OpenJDK11U-jdk_x64_linux_hotspot_11.0.32.1_1.tar.gz -O openjdk.tar.gz && \
    tar -zxvf openjdk.tar.gz && \
    rm openjdk.tar.gz
ENV JAVA_HOME=/opt/jdk-11.0.32.1+1
ENV PATH=$JAVA_HOME/bin:$PATH

RUN mkdir cromwell && \
    cd cromwell && \
    wget http://e-hpc-hangzhou.oss-cn-hangzhou.aliyuncs.com/softwares/ehpc-public-data/cromwell/cromwell-81-latest.jar -O cromwell.jar
COPY ./cromwell.conf /opt/cromwell/cromwell.conf

RUN mkdir quartet

COPY scripts /opt/quartet/scripts
COPY omics_qc.py /opt/quartet/omics_qc.py
COPY workflows /opt/quartet/workflows

ENTRYPOINT ["/opt/quartet/omics_qc.py"]
