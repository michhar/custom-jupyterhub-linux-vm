#!/bin/bash
sudo docker run -it -v /var/run/docker.sock:/var/run/docker.sock -p 8788:8788 --expose=8788 rheartpython/cvopenhack:latest
