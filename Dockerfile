FROM phusion/baseimage:0.11

LABEL maintainer="Kyle Wilcox <kyle@axiomdatascience.com>" \
      description='The GUTILS container'

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]
ENV KILL_PROCESS_TIMEOUT 30
ENV KILL_ALL_PROCESSES_TIMEOUT 30

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y \
        binutils \
        build-essential \
        bzip2 \
        ca-certificates \
        file \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender1 \
        pwgen \
        wget \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setup CONDA (https://hub.docker.com/r/continuumio/miniconda3/~/dockerfile/)
ENV MINICONDA_VERSION py38_4.8.2
ENV MINICONDA_SHA256 5bbb193fd201ebe25f4aeb3c58ba83feced6a25982ef4afa86d5506c3656c142
RUN curl -k -o /miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-$MINICONDA_VERSION-Linux-x86_64.sh && \
    echo $MINICONDA_SHA256 /miniconda.sh | sha256sum --check && \
    /bin/bash /miniconda.sh -b -p /opt/conda && \
    rm /miniconda.sh && \
    /opt/conda/bin/conda clean -afy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> /etc/profile && \
    echo "conda activate base" >> /etc/profile && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda install -y -c conda-forge -n base mamba && \
    /opt/conda/bin/conda clean -afy

ENV PATH /opt/conda/bin:$PATH

COPY environment.yml /tmp/environment.yml
RUN mamba env update \
        -n base \
        -f /tmp/environment.yml \
        && \
    mamba clean -afy

ENV PATH /opt/conda/bin:$PATH

ENV GUTILS_DEPLOYMENTS_DIRECTORY /gutils/deployments
ENV GUTILS_ERDDAP_CONTENT_PATH /gutils/erddap/content
ENV GUTILS_ERDDAP_FLAG_PATH /gutils/erddap/flag
VOLUME ["${GUTILS_DEPLOYMENTS_DIRECTORY}", "${GUTILS_ERDDAP_CONTENT_PATH}", "${GUTILS_ERDDAP_FLAG_PATH}"]

RUN mkdir -p /etc/my_init.d && \
    mkdir -p /gutils
COPY docker/init/* /etc/my_init.d/

ENV GUTILS_VERSION 3.1.0

ENV PROJECT_ROOT /code
RUN mkdir -p "$PROJECT_ROOT"
COPY . $PROJECT_ROOT
RUN cd $PROJECT_ROOT && pip install --no-deps .
WORKDIR $PROJECT_ROOT
