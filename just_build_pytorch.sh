#!/bin/bash

# PyTorch post-1.0rc1 (C++ module issue in 1.0rc1 and old cmake)
# https://github.com/pytorch/pytorch/pull/13492
# Also see a previous important commit for using old cmake:  https://github.com/pytorch/pytorch/pull/13013

PYTORCH_COMMIT_ID="8619230"

git clone https://github.com/pytorch/pytorch.git &&\
    cd pytorch && git checkout ${PYTORCH_COMMIT_ID} && \
    git submodule update --init --recursive  &&\
    pip3 install pyyaml==3.13 &&\
    pip3 install -r requirements.txt &&\
    USE_OPENCV=1 \
    BUILD_TORCH=ON \
    CMAKE_PREFIX_PATH="/usr/bin/" \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/lib:$LD_LIBRARY_PATH \
    CUDA_BIN_PATH=/usr/local/cuda/bin \
    CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda/ \
    CUDNN_LIB_DIR=/usr/local/cuda/lib64 \
    CUDA_HOST_COMPILER=cc \
    USE_CUDA=1 \
    USE_NNPACK=1 \
    CC=cc \
    CXX=c++ \
    TORCH_CUDA_ARCH_LIST="3.5 5.2 6.0 6.1+PTX" \
    TORCH_NVCC_FLAGS="-Xfatbin -compress-all" \
    python3 setup.py bdist_wheel

pip3 install dist/*.whl
rm -fr pytorch