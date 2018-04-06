#!/bin/bash
sudo docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 5555:5555 -p 80:7842 -p 8787:8787 -p 8786:8786 -p 8788:8788 --expose=8788 rheartpython/cvopenhack:latest
