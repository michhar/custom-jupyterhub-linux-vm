#!/bin/bash
sudo docker run --runtime=nvidia -d -p 5555:5555 -p 80:7842 -p 8788:8788 -v ~/dev/:/root/sharedfolder --expose=8788  rheartpython/cvdeep_gpu:latest