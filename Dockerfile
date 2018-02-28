FROM microsoft/cntk:2.4-cpu-python3.5

LABEL maintainer "MICROSOFT CORPORATION"

# Docker install
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    nodejs \
    npm

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Object Detection
RUN apt-get update && apt-get install -y docker-ce && apt-get install -y --no-install-recommends \
        cmake \
        git \
        libopencv-dev \
        nvidia-cuda-toolkit \
        && \
    apt-get -y autoremove \
        && \
    rm -rf /var/lib/apt/lists/*

# Add user
ARG USER_PW
RUN USER_PW=$USER_PW
RUN useradd wonderwoman
RUN printf "${USER_PW}\n${USER_PW}" | passwd wonderwoman
RUN mkhomedir_helper wonderwoman

# Get Anaconda installed into /opt
RUN su - wonderwoman
RUN cd /home/wonderwoman
# RUN mkdir -p /opt/anaconda3
RUN curl -O https://repo.continuum.io/archive/Anaconda3-4.1.1-Linux-x86_64.sh
RUN chmod u+x Anaconda3-4.1.1-Linux-x86_64.sh
RUN printf 'yes\nyes\n/opt/anaconda3/' | bash Anaconda3-4.1.1-Linux-x86_64.sh

# Create the conda environment
RUN /opt/anaconda3/bin/conda create -n py35 python=3.5.2

# General Installs
RUN /opt/anaconda3/envs/py35/bin/conda install -y -n py35 cython boost
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && pip install dlib easydict pyyaml'
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && pip install --upgrade numpy opencv-python jupyterhub notebook scikit-learn pandas matplotlib'

# Tensorflow latest
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && pip install tensorflow'

# Object Detection with CNTK and Custom Vision Service Python libraries
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && pip install https://cntk.ai/PythonWheel/CPU-Only/cntk-2.4-cp35-cp35m-linux_x86_64.whl'
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && cd /cntk/Examples/Image/Detection/utils && git clone https://github.com/CatalystCode/py-faster-rcnn.git && cd py-faster-rcnn/lib && python setup.py build_ext --inplace'
RUN cp /cntk/Examples/Image/Detection/utils/py-faster-rcnn/lib/pycocotools/_mask.cpython-35m-x86_64-linux-gnu.so /cntk/Examples/Image/Detection/utils/cython_modules/ 
RUN cp /cntk/Examples/Image/Detection/utils/py-faster-rcnn/lib/utils/cython_bbox.cpython-35m-x86_64-linux-gnu.so /cntk/Examples/Image/Detection/utils/cython_modules/ 
RUN cp /cntk/Examples/Image/Detection/utils/py-faster-rcnn/lib/nms/gpu_nms.cpython-35m-x86_64-linux-gnu.so /cntk/Examples/Image/Detection/utils/cython_modules/ 
RUN cp /cntk/Examples/Image/Detection/utils/py-faster-rcnn/lib/nms/cpu_nms.cpython-35m-x86_64-linux-gnu.so /cntk/Examples/Image/Detection/utils/cython_modules/ 

WORKDIR /cntk/Examples/Image/Detection/FasterRCNN
RUN bash -c 'git config --system core.longpaths true'
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && pip install "git+https://github.com/Azure/azure-sdk-for-python#egg=azure-cognitiveservices-vision-customvision&subdirectory=azure-cognitiveservices-vision-customvision"'
COPY . /cv_workshop
WORKDIR /cv_workshop

RUN bash -c 'source /opt/anaconda3/bin/activate py35 && pip install -r cli-requirements.txt'

# To get data
# RUN bash -c 'source /opt/anaconda3/bin/activate py35 && python -u cvworkshop_utils.py'  

# PyTorch
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && /opt/anaconda3/envs/py35/bin/conda install pytorch torchvision -c pytorch'
# # Install Torchnet, a high-level framework for PyTorch
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && pip install git+https://github.com/pytorch/tnt.git@master'
# RUN bash -c 'source /opt/anaconda3/bin/activate py35 && pip install torchvision psutil'

# Jupyterhub

# Installs
RUN sudo apt-get install nodejs npm
RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN npm install -g configurable-http-proxy
RUN bash -c 'source /opt/anaconda3/bin/activate && pip install jupyterhub==0.7.2'

# Create directories
RUN mkdir -p /etc/init.d/jupyterhub
RUN chmod +x /etc/init.d/jupyterhub
RUN chmod +x /etc/init.d/jupyterhub
RUN mkdir -p /etc/jupyterhub
RUN chmod +x /etc/jupyterhub

# Deal with directory permissions for user and add to userlist
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && mkdir -p /hub/user/wonderwoman/'
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && sudo chown wonderwoman /hub/user/wonderwoman/'
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && mkdir -p /user/wonderwoman/'
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && sudo chown wonderwoman /user/wonderwoman/'
# fyi, this was for docker-compose
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && echo "wonderwoman admin" >> /etc/jupyterhub/userlist' 
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && sudo chown wonderwoman /etc/jupyterhub'
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && sudo chown wonderwoman /etc/jupyterhub'


# An attempt to fix the permission error for jupyterhub-singleuser
# RUN bash -c 'source /cntk/activate-cntk && sudo chgrp shadow /etc/shadow'
# RUN bash -c 'source /cntk/activate-cntk && sudo chmod g+r /etc/shadow'
# RUN bash -c 'source /cntk/activate-cntk && sudo usermod -a -G shadow wonderwoman'

# To fix jupyter user in jupyter.sqlist issues:
RUN rm jupyterhub.sqlite
RUN rm jupyterhub_cookie_secret

# Create a default config to /etc/jupyterhub/jupyterhub_config.py
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && jupyterhub --generate-config -f /etc/jupyterhub/jupyterhub_config.py'
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && echo c.PAMAuthenticator.open_sessions=False >> /etc/jupyterhub/jupyterhub_config.py'
RUN bash -c "source /opt/anaconda3/bin/activate py35 && echo c.Authenticator.whitelist={\'wonderwoman\'} >> /etc/jupyterhub/jupyterhub_config.py"
RUN bash -c "source /opt/anaconda3/bin/activate py35 && echo c.LocalAuthenticator.create_system_users=True >> /etc/jupyterhub/jupyterhub_config.py"
RUN bash -c "source /opt/anaconda3/bin/activate py35 && echo c.Authenticator.admin_users={\'wonderwoman\'} >> /etc/jupyterhub/jupyterhub_config.py"

# Copy TLS certificate and key
ENV SSL_CERT /etc/jupyterhub/secrets/mycert.pem
ENV SSL_KEY /etc/jupyterhub/secrets/mykey.key
COPY ./secrets/*.crt $SSL_CERT
COPY ./secrets/*.key $SSL_KEY
RUN chmod 700 /etc/jupyterhub/secrets && \
    chmod 600 /etc/jupyterhub/secrets/*

# User list
RUN bash -c 'source /opt/anaconda3/bin/activate py35 && cp ./userlist /etc/jupyterhub/userlist'

CMD bash -c "source /opt/anaconda3/bin/activate py35 && jupyterhub -f /etc/jupyterhub/jupyterhub_config.py --JupyterHub.hub_ip=0.0.0.0 --JupyterHub.ip=0.0.0.0 JupyterHub.cookie_secret=bytes.fromhex\('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'\) Spawner.cmd=\['/opt/anaconda3/bin/jupyterhub-singleuser'\] --ip 0.0.0.0 --ssl-key /etc/jupyterhub/secrets/mykey.key --ssl-cert /etc/jupyterhub/secrets/mycert.pem"
