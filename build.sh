#!/bin/bash
#==============================================================================
#
# build.sh
#
#==============================================================================
#
# Project build script.
#
# Requires the following programs:
#
# docker
# aws-cli
#
# Usage: ./build.sh [-d|--device <cpu|cuda>] <command> <command>
#
# Commands:
#
#   dockerInstall - Creates the docker images, installs it in the local repository
#                   and updates the "latest" tags to point to the images.
#

set -e

DOCKER_USER=aif
DOCKER_IMAGE="celebamask-hq.face_parsing"
DEVICE='cuda'
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


#------------------------------------------------------------------------------
# GET AWS CREDS LOCAL
#------------------------------------------------------------------------------
function getAwsCredsLocal() {
    local aws_profile
    aws_profile="default"
    
    eval $1=$(aws --profile $aws_profile configure get aws_access_key_id)
    eval $2=$(aws --profile $aws_profile configure get aws_secret_access_key)
}

#------------------------------------------------------------------------------
# DOCKER INSTALL
#------------------------------------------------------------------------------
function dockerInstall() {
    local major
    local minor
    local patch
    local snapshot
    local docker_base
    local aws_secret
    local temp_creds
    
    parseVersion major minor patch snapshot
    version="${major}.${minor}.${patch}${snapshot}"
    
    temp_creds=$(mktemp)
    
    if [ "$DEVICE" = "cuda" ]
    then
        docker_base="nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04"
    else
        docker_base="ubuntu:18.04"
    fi
    
    if [ -f "$HOME/.aws/credentials" ]; then
       aws_secret="--secret id=aws_creds,src=$HOME/.aws/credentials"
    else
       aws_secret="--secret id=aws_creds,src=$temp_creds"
    fi
    
    pushd ${SCRIPT_DIR}/face_parsing
    DOCKER_BUILDKIT=1 docker build $aws_secret --build-arg BASE_IMAGE="$docker_base" -t ${DOCKER_USER}/${DOCKER_IMAGE}:${version} .
    docker tag ${DOCKER_USER}/${DOCKER_IMAGE}:${version} ${DOCKER_USER}/${DOCKER_IMAGE}:latest
    popd
    
    rm -f $temp_creds
}

#------------------------------------------------------------------------------
# PARSE VERSION
#------------------------------------------------------------------------------
function parseVersion() {
    version=`cat "${SCRIPT_DIR}/VERSION"`
    local RE='[^0-9]*\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\)\([0-9A-Za-z-]*\)'
    # MAJOR
    eval $1=`echo ${version} | sed -e "s#$RE#\1#"`
    # MINOR
    eval $2=`echo ${version} | sed -e "s#$RE#\2#"`
    # PATCH
    eval $3=`echo ${version} | sed -e "s#$RE#\3#"`
    # SNAPSHOT
    eval $4=`echo ${version} | sed -e "s#$RE#\4#"`
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -d|--device)
      DEVICE="$2"
      shift # past argument
      shift # past value
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

for i in "$@" 
do
    case $i in
        dockerInstall)
            dockerInstall
            shift
            ;;
        *)
            ;;
    esac
done


