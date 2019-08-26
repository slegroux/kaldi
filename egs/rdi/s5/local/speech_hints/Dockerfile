FROM ubuntu:18.10
LABEL maintainer="sylvainlg@voicea.ai"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        g++ \
        make \
        automake \
        autoconf \
        bzip2 \
        unzip \
        wget \
        sox \
        libtool \
        git \
        subversion \
        python2.7 \
        python3 \
        zlib1g-dev \
        ca-certificates \
        patch \
        ffmpeg \
        swig \
        python2.7-dev \
        python2.7-setuptools \
        python2.7-numpy \
        python-pip \
	emacs-nox && \
    pip install awscli && \
    rm -rf /var/lib/apt/lists/*


#RUN ln -s /usr/bin/python2.7 /usr/bin/python 

RUN git clone --depth 1 https://github.com/slegroux/kaldi.git /opt/kaldi && \
    cd /opt/kaldi && \
    cd /opt/kaldi/tools && \
    ./extras/install_mkl.sh && \
    ./extras/install_sequitur.sh && \
    /bin/bash -c "source env.sh" && \
    make -j $(nproc) && \
    cd /opt/kaldi/src && \
    ./configure --shared && \
    make depend -j $(nproc) && \
    make -j $(nproc)

WORKDIR /opt/kaldi/