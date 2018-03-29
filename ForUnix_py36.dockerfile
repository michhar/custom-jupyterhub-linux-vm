# Build with: docker build --build-arg USER_PW=$USER_PASSWD -t rheartpython/cvopenhack:unix -f Dockerfile.py36 .
# Run with:  sudo docker run -it -v /var/run/docker.sock:/var/run/docker.sock -p 8788:8788 --expose=8788 rheartpython/cvopenhack:unix
FROM microsoft/cntk:2.4-cpu-python3.5
USER root

LABEL maintainer "ML OpenHack Team (contact michhar <at> microsoft.com)"
ENV PYTORCH_VERSION="0.3.0.post4-cp36-cp36m-linux_x86_64"
ENV TENSORFLOW_VERSION="1.6.0"
ENV CNTK_VERSION="2.4-cp36-cp36m-linux_x86_64"
ENV KERAS_VERSION="2.1.4"

# Docker install etc. (first repo add is for libpython3.6-dev)
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

RUN apt-get update && apt-get install -y docker-ce && apt-get install -y --no-install-recommends \
        cmake \
        git \
        libopencv-dev \
        nvidia-cuda-toolkit \
        && \
    apt-get -y autoremove \
        && \
    rm -rf /var/lib/apt/lists/*

# Add admin user (other users can be made admins of jupyterhub from this user)
ARG USER_PW
RUN USER_PW=$USER_PW

# Add some more users (to remove windows endings may have to: tr -d '\015' <DOS-file >UNIX-file)
ADD add_users.sh /
RUN chmod +x /add_users.sh
RUN bash -c '. /add_users.sh'

# Configure environment
ENV CONDA_DIR=/user/anaconda3/ \
    SHELL=/bin/bash \
    NB_USER=wonderwoman \
    NB_UID=999 \
    NB_GID=100 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

# ADD fix-permissions /usr/bin/fix-permissions
# Create jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME && \
    chmod -R 777 $CONDA_DIR

RUN printf "${USER_PW}\n${USER_PW}" | passwd wonderwoman

USER $NB_UID

# Setup work directory for backward-compatibility
RUN mkdir /home/$NB_USER/work && \
    chmod -R 777 /home/$NB_USER

# Install Python (conda) as jovyan and check the md5 sum provided on the download site
RUN cd /tmp && \
    wget --quiet https://repo.continuum.io/archive/Anaconda3-5.1.0-Linux-x86_64.sh && \
    /bin/bash Anaconda3-5.1.0-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Anaconda3-5.1.0-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda config --system --prepend channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    $CONDA_DIR/bin/conda config --system --set show_channel_urls true && \
    $CONDA_DIR/bin/conda update --all --quiet --yes && \
    conda clean -tipsy && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    chmod -R 777 $CONDA_DIR && \
    chmod -R 777 /home/$NB_USER

# Create the conda environment
RUN $CONDA_DIR/bin/conda create -n py36

# General Installs
RUN bash -c 'source /user/anaconda3/bin/activate py36 && conda install -y -n py36 cython boost'
RUN bash -c 'source /user/anaconda3/bin/activate py36 && pip install dlib easydict pyyaml'

# Tensorflow and Keras
RUN bash -c 'source /user/anaconda3/bin/activate py36 && pip install tensorflow==${TENSORFLOW_VERSION}'
RUN bash -c 'source /user/anaconda3/bin/activate py36 && pip install keras==${KERAS_VERSION}'

# CNTK and Custom Vision Service Python libraries
RUN bash -c 'source /user/anaconda3/bin/activate py36 && pip install https://cntk.ai/PythonWheel/CPU-Only/cntk-${CNTK_VERSION}.whl'

USER root

RUN bash -c 'git config --system core.longpaths true'
RUN bash -c 'source /user/anaconda3/bin/activate py36 && pip install "git+https://github.com/Azure/azure-sdk-for-python#egg=azure-cognitiveservices-vision-customvision&subdirectory=azure-cognitiveservices-vision-customvision"'

COPY . /hub/user/

RUN mkdir /hub/user/data
# To get data
RUN curl -O https://challenge.blob.core.windows.net/challengefiles/gear_images.zip
RUN curl -O https://challenge.blob.core.windows.net/challengefiles/gear_images_testset.zip
RUN cp *.zip /hub/user/data

WORKDIR /hub/user/

RUN bash -c 'source /user/anaconda3/bin/activate py36 && pip install -r cli-requirements.txt'
RUN bash -c 'source /user/anaconda3/bin/activate py36 && pip install -r requirements.txt'

# PyTorch
RUN bash -c 'source /user/anaconda3/bin/activate py36 && pip install http://download.pytorch.org/whl/cu80/torch-${PYTORCH_VERSION}.whl'
RUN bash -c 'source /user/anaconda3/bin/activate py36 && pip install torchvision==0.2.0'
# Install Torchnet, a high-level framework for PyTorch
RUN bash -c 'source /user/anaconda3/bin/activate py36 && pip install git+https://github.com/pytorch/tnt.git@master'
RUN bash -c 'source /user/anaconda3/bin/activate py36 && pip install torchvision psutil'

### Jupyterhub setup ###

# Additional installs
RUN sudo apt-get install nodejs npm
RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN npm install -g configurable-http-proxy

# Create directories
RUN mkdir -p /etc/init.d/jupyterhub
RUN chmod +x /etc/init.d/jupyterhub
RUN chmod +x /etc/init.d/jupyterhub
RUN mkdir -p /etc/jupyterhub
RUN chmod +x /etc/jupyterhub

# Deal with directory permissions for user and add to userlist
RUN bash -c 'source /user/anaconda3/bin/activate py36 && mkdir -p /hub/user/wonderwoman/'
RUN bash -c 'source /user/anaconda3/bin/activate py36 && sudo chown wonderwoman /hub/user/wonderwoman/'
RUN bash -c 'source /user/anaconda3/bin/activate py36 && mkdir -p /user/wonderwoman/'
RUN bash -c 'source /user/anaconda3/bin/activate py36 && sudo chown wonderwoman /user/wonderwoman/'
# fyi, this was for docker-compose
RUN bash -c 'source /user/anaconda3/bin/activate py36 && echo "wonderwoman admin" >> /etc/jupyterhub/userlist' 
RUN bash -c 'source /user/anaconda3/bin/activate py36 && sudo chown wonderwoman /etc/jupyterhub'
RUN bash -c 'source /user/anaconda3/bin/activate py36 && sudo chown wonderwoman /etc/jupyterhub'

# Create a default config to /etc/jupyterhub/jupyterhub_config.py
RUN bash -c 'source /user/anaconda3/bin/activate py36 && jupyterhub --generate-config -f /etc/jupyterhub/jupyterhub_config.py'
RUN bash -c 'source /user/anaconda3/bin/activate py36 && echo c.PAMAuthenticator.open_sessions=False >> /etc/jupyterhub/jupyterhub_config.py'
RUN bash -c "source /user/anaconda3/bin/activate py36 && echo c.Authenticator.whitelist={\'wonderwoman\'} >> /etc/jupyterhub/jupyterhub_config.py"
RUN bash -c "source /user/anaconda3/bin/activate py36 && echo c.LocalAuthenticator.create_system_users=True >> /etc/jupyterhub/jupyterhub_config.py"
RUN bash -c "source /user/anaconda3/bin/activate py36 && echo c.Authenticator.admin_users={\'wonderwoman\'} >> /etc/jupyterhub/jupyterhub_config.py"

# Copy TLS certificate and key
ENV SSL_CERT /etc/jupyterhub/secrets/mycert.pem
ENV SSL_KEY /etc/jupyterhub/secrets/mykey.key
COPY ./secrets/*.crt $SSL_CERT
COPY ./secrets/*.key $SSL_KEY
RUN chmod 700 /etc/jupyterhub/secrets && \
    chmod 600 /etc/jupyterhub/secrets/*

# For CNTK (libpython3.6-dev needed)
RUN add-apt-repository ppa:jonathonf/python-3.6 && apt-get update && apt-get install -y libpython3.6-dev

CMD bash -c "source /user/anaconda3/bin/activate py36 && jupyterhub -f /etc/jupyterhub/jupyterhub_config.py --JupyterHub.Authenticator.whitelist=\{\'user1\',\'user2\',\'user3\',\'user4\',\'user5\',\'user6\'\} --JupyterHub.hub_ip='' --JupyterHub.ip='' JupyterHub.cookie_secret=bytes.fromhex\('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'\) Spawner.cmd=\['/user/anaconda3/bin/jupyterhub-singleuser'\] --ip '' --port 8788 --ssl-key /etc/jupyterhub/secrets/mykey.key --ssl-cert /etc/jupyterhub/secrets/mycert.pem"
