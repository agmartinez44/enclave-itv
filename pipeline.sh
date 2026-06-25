#!/bin/bash
set -euo pipefail

SHA=$(git rev-parse --short HEAD) && \
docker build -t enclave-itv:$SHA -t enclave-itv:latest -f ./app/Dockerfile . && \
docker save enclave-itv:$SHA enclave-itv:latest -o enclave-itv.tar && \
kind load image-archive enclave-itv.tar 
rm -f enclave-itv.tar
