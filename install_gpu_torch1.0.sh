#!/bin/bash
sudo nvidia-docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 8788:8788 --expose=8788 rheartpython/cvdeep_gpu:latest
