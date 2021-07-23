# syntax = docker/dockerfile:1.2

#
# Usage:
#
# docker build . -t face_parsing
#


ARG BASE_IMAGE=nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04

FROM $BASE_IMAGE

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        curl \
        git \
        mesa-utils \
        unzip \
        wget \
        awscli

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/Miniconda3-latest-Linux-x86_64.sh && \
    bash /tmp/Miniconda3-latest-Linux-x86_64.sh -b && \
    rm /tmp/Miniconda3-latest-Linux-x86_64.sh


RUN mkdir -p /opt/face_parsing

WORKDIR /opt/face_parsing

ENV PATH /root/miniconda3/bin:$PATH

COPY environment.yml ./
RUN conda env create -f environment.yml

RUN --mount=type=secret,id=aws_creds mkdir -p models/parsenet && \
    mkdir -p /root/.aws && \
    cat /run/secrets/aws_creds > /root/.aws/credentials && \
    aws s3 cp s3://aif-dev-deeptwin-pipeline/models/thirdparty/CelebAMask-HQ/face_parsing/model.pth models/parsenet
    
COPY *.py ./
COPY Data_preprocessing ./

ENV PATH /root/miniconda3/envs/face_parsing/bin:$PATH
