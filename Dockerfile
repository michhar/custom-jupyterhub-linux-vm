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

RUN /root/anaconda3/envs/cntk-py35/bin/conda install -y -n cntk-py35 cython boost
RUN bash -c 'source /cntk/activate-cntk && pip install dlib easydict pyyaml'
RUN bash -c 'source /cntk/activate-cntk && cd /cntk/Examples/Image/Detection/utils && git clone https://github.com/CatalystCode/py-faster-rcnn.git && cd py-faster-rcnn/lib && python setup.py build_ext --inplace'
# RUN cp /cntk/Examples/Image/Detection/utils/py-faster-rcnn/lib/pycocotools/_mask.cpython-35m-x86_64-linux-gnu.so /cntk/Examples/Image/Detection/utils/cython_modules/ 
# RUN cp /cntk/Examples/Image/Detection/utils/py-faster-rcnn/lib/utils/cython_bbox.cpython-35m-x86_64-linux-gnu.so /cntk/Examples/Image/Detection/utils/cython_modules/ 
# RUN cp /cntk/Examples/Image/Detection/utils/py-faster-rcnn/lib/nms/gpu_nms.cpython-35m-x86_64-linux-gnu.so /cntk/Examples/Image/Detection/utils/cython_modules/ 
# RUN cp /cntk/Examples/Image/Detection/utils/py-faster-rcnn/lib/nms/cpu_nms.cpython-35m-x86_64-linux-gnu.so /cntk/Examples/Image/Detection/utils/cython_modules/ 

# WORKDIR /cntk/Examples/Image/Detection/FasterRCNN
# RUN bash -c 'git config --system core.longpaths true'
# RUN bash -c 'source /cntk/activate-cntk && pip install "git+https://github.com/Azure/azure-sdk-for-python#egg=azure-cognitiveservices-vision-customvision&subdirectory=azure-cognitiveservices-vision-customvision"'
COPY . /cv_workshop
WORKDIR /cv_workshop
# RUN bash -c 'source /cntk/activate-cntk && pip install opencv-python'
# RUN bash -c 'source /cntk/activate-cntk && pip install -r cli-requirements.txt'

# To get data
# RUN bash -c 'source /cntk/activate-cntk && python -u cvworkshop_utils.py'  

# # Torch
# RUN bash -c 'source /cntk/activate-cntk && pip install http://download.pytorch.org/whl/cu80/torch-0.2.0.post3-cp35-cp35m-manylinux1_x86_64.whl'
# # Install Torchnet, a high-level framework for PyTorch
# RUN bash -c 'source /cntk/activate-cntk && pip install git+https://github.com/pytorch/tnt.git@master'
# RUN bash -c 'source /cntk/activate-cntk && pip install torchvision psutil'

# Jupyterhub

# Installs
RUN sudo apt-get install nodejs npm
RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN npm install -g configurable-http-proxy
RUN bash -c 'source /cntk/activate-cntk && pip install jupyterhub==0.7.2'

# Create directories
RUN mkdir -p /etc/init.d/jupyterhub
RUN chmod +x /etc/init.d/jupyterhub
RUN chmod +x /etc/init.d/jupyterhub
RUN mkdir -p /etc/jupyterhub
RUN chmod +x /etc/jupyterhub

# Add a user and add to userlist
ARG USER_PW
RUN USER_PW=$USER_PW
RUN bash -c 'source /cntk/activate-cntk && useradd -g root wonderwoman'
RUN printf "${USER_PW}\n${USER_PW}" | passwd wonderwoman
RUN bash -c 'source /cntk/activate-cntk && mkhomedir_helper wonderwoman'
RUN bash -c 'source /cntk/activate-cntk && mkdir -p /hub/user/wonderwoman/'
RUN bash -c 'source /cntk/activate-cntk && sudo chown wonderwoman /hub/user/wonderwoman/'
RUN bash -c 'source /cntk/activate-cntk && mkdir -p /user/wonderwoman/'
RUN bash -c 'source /cntk/activate-cntk && sudo chown wonderwoman /user/wonderwoman/'
RUN bash -c 'source /cntk/activate-cntk && echo "wonderwoman admin" >> /etc/jupyterhub/userlist' # this was for docker-compose
RUN bash -c 'source /cntk/activate-cntk && sudo chown wonderwoman /etc/jupyterhub'
RUN bash -c 'source /cntk/activate-cntk && sudo chown wonderwoman /etc/jupyterhub'


# An attempt to fix the permission error for jupyterhub-singleuser
RUN bash -c 'source /cntk/activate-cntk && sudo chmod ugo+rx /root/anaconda3/envs/cntk-py35/bin/jupyterhub-singleuser'
# RUN bash -c 'source /cntk/activate-cntk && sudo chgrp shadow /etc/shadow'
# RUN bash -c 'source /cntk/activate-cntk && sudo chmod g+r /etc/shadow'
# RUN bash -c 'source /cntk/activate-cntk && sudo usermod -a -G shadow wonderwoman'

# To fix jupyter user in jupyter.sqlist issues:
RUN rm jupyterhub.sqlite
RUN rm jupyterhub_cookie_secret

# Create a default config to /etc/jupyterhub/jupyterhub_config.py
RUN bash -c 'source /cntk/activate-cntk && jupyterhub --generate-config -f /etc/jupyterhub/jupyterhub_config.py'

RUN bash -c 'source /cntk/activate-cntk && echo c.PAMAuthenticator.open_sessions=False >> /etc/jupyterhub/jupyterhub_config.py'

RUN bash -c "source /cntk/activate-cntk && echo c.Authenticator.whitelist={\'wonderwoman\'} >> /etc/jupyterhub/jupyterhub_config.py"
RUN bash -c "source /cntk/activate-cntk && echo c.LocalAuthenticator.create_system_users=True >> /etc/jupyterhub/jupyterhub_config.py"

RUN bash -c "source /cntk/activate-cntk && echo c.Authenticator.admin_users={\'wonderwoman\'} >> /etc/jupyterhub/jupyterhub_config.py"
# RUN bash -c 'source /cntk/activate-cntk && jupyterhub upgrade-db'
RUN bash -c 'source /cntk/activate-cntk && sudo chmod ugo+rx /root/anaconda3/envs/cntk-py35/bin/jupyterhub-singleuser'

# RUN bash -c 'source /cntk/activate-cntk && openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
#     -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" \
#     -keyout mykey.key  -out mycert.pem'

# Install dockerspawner, oauth, postgres
# RUN /root/anaconda3/envs/cntk-py35/bin/conda install -yq psycopg2=2.7 && \
#     /root/anaconda3/envs/cntk-py35/bin/conda clean -tipsy && \
#     /root/anaconda3/envs/cntk-py35/bin/pip install --no-cache-dir \
#         oauthenticator==0.7.* \
#         dockerspawner==0.9.*

# Copy TLS certificate and key
ENV SSL_CERT /etc/jupyterhub/secrets/mycert.pem
ENV SSL_KEY /etc/jupyterhub/secrets/mykey.key
COPY ./secrets/*.crt $SSL_CERT
COPY ./secrets/*.key $SSL_KEY
RUN chmod 700 /etc/jupyterhub/secrets && \
    chmod 600 /etc/jupyterhub/secrets/*

# RUN bash -c 'source /cntk/activate-cntk && cp ./jupyterhub_config.py /etc/jupyterhub/jupyterhub_config.py'

# Create a superuser
# This starts by creating an argument for building and is a user password from the build system
# When building add "--build-arg USER_PW=$USER_PASSWD" for system var $USER_PASSWD which you've set
# ENV bash -c 'source /cntk/activate-cntk && USER_PW=$USER_PW'
# RUN bash -c 'source /cntk/activate-cntk && useradd -ms /bin/bash wonderwoman'
# RUN bash -c 'source /cntk/activate-cntk && printf "${USER_PW}\n${USER_PW}" | passwd wonderwoman'
# RUN bash -c 'source /cntk/activate-cntk && mkhomedir_helper wonderwoman'
# RUN bash -c 'source /cntk/activate-cntk && mkdir -p /hub/user/wonderwoman/'
# RUN bash -c 'source /cntk/activate-cntk && chown wonderwoman /hub/user/wonderwoman/'

# User list
RUN bash -c 'source /cntk/activate-cntk && cp ./userlist /etc/jupyterhub/userlist'

CMD bash -c "source /cntk/activate-cntk && jupyterhub -f /etc/jupyterhub/jupyterhub_config.py --JupyterHub.hub_ip=0.0.0.0 JupyterHub.cookie_secret = bytes.fromhex\('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'\) --ip 0.0.0.0 --ssl-key /etc/jupyterhub/secrets/mykey.key --ssl-cert /etc/jupyterhub/secrets/mycert.pem"

RUN bash -c "source /cntk/activate-cntk && chown wonderwoman /root/anaconda3/envs/cntk-py35/bin/jupyterhub-singleuser"
# RUN sudo chmod 777 /root/anaconda3/envs/cntk-py35/bin/jupyterhub-singleuser
