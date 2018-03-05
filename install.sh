#!/bin/bash
sudo docker run -it -v /var/run/docker.sock:/var/run/docker.sock -p 8000:8000 --expose=8000 rheartpython/cvopenhack:unix
