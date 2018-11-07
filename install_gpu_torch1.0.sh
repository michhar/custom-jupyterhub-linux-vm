#!/bin/bash
sudo nvidia-docker run -d -p 8788:8788 -v ~/dev/:/root/sharedfolder --expose=8788  rheartpython/cvdeep_gpu:torch1.0alpha
