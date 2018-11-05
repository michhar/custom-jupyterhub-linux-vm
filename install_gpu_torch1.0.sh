#!/bin/bash

sudo nvidia-docker run -d -p 5555:5555 -p 80:7842 -p 8788:8788 -v ~/dev/:/root/sharedfolder --expose=8788  rheartpython/cvdeep_gpu:torch1.0alpha

# sudo nvidia-docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 5555:5555 -p 80:7842 -p 8788:8788 --expose=8788 rheartpython/cvdeep_gpu:torch1.0alpha