############################################
# For an Ubuntu Deep Learning frameworks environment
# running Jupyterhub.
#
# Build with the following:
#  docker build --build-arg USER_PW=$USER_PASSWD -t rheartpython/cvdeep -f Linux_py36.dockerfile .
#
# Run with:
# docker run -it -v /var/run/docker.sock:/var/run/docker.sock -p 8788:8788 --expose=8788 rheartpython/cvdeep:latest
# 
# Log in to Jupyterhub at https://localhost:8788 with
# password specified in the environment variable
# $USER_PASSWD and username wonderwoman.
############################################

FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04

LABEL maintainer "Micheleen Harris (contact michhar <at> microsoft.com)"
ENV TENSORFLOW_VERSION="1.6.0"
ENV CNTK_VERSION="2.5"
ENV KERAS_VERSION="2.1.4"
ENV PYTORCH_VERSION="0.3.1"
ENV TORCHVISION_VERION="0.2.0"

RUN apt-get update && apt-get install -y \
    apt-transport-https \
    software-properties-common \
    nodejs \
    npm \
    zip \
    sudo

RUN apt-get update && apt-get install -y --no-install-recommends \
         build-essential \
         cmake \
         git \
         curl \
         vim \
         ca-certificates \
         openmpi-bin \
         libjpeg-dev \
         libpng-dev &&\
     rm -rf /var/lib/apt/lists/*

# Openmpi v3 (https://www.open-mpi.org/software/ompi/v3.0/) - may take some time to install
# RUN cd /tmp && \
#     curl -O https://www.open-mpi.org/software/ompi/v3.0/downloads/openmpi-3.0.1.tar.gz && \
#     tar -xzvf ./openmpi-3.0.1.tar.gz && \
#     cd openmpi-3.0.1 && \
#     ./configure --prefix=/usr/local/mpi && \
#     make -j all && \
#     make install && \
#     rm ../openmpi-3.0.1.tar.gz
ENV PATH=/usr/local/mpi/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/mpi/lib:$LD_LIBRARY_PATH

# For Protobuf and zlib1g-dev/python-dev/bzip2 for Boost
RUN apt-get update && apt-get install -y \
    autoconf  \
    automake \
    libtool \
    make \
    g++ \
    unzip \
    zlib1g-dev \
    python-dev \
    wget \
    bzip2 \
    # For TF Object Detection API
    protobuf-compiler python-pil python-lxml python-tk

# # Cython for TF Object Detection API - Cython
# RUN apt-get update && apt-get install -y python3-pip && \
#     pip3 install Cython

# # For TF Object Detection API - wip and skipping for now
# RUN git clone https://github.com/cocodataset/cocoapi.git && \
#     cd cocoapi/PythonAPI && \
#     make
#     # && \
#     # mkdir /tmp && \
#     # cp -r . /tmp
#     # && \
#     # git clone https://github.com/tensorflow/models.git && \
#     # cp -r pycocotools ./research/

# MKL (for CNTK and others)
RUN mkdir /usr/local/mklml && \
    wget https://github.com/01org/mkl-dnn/releases/download/v0.12/mklml_lnx_2018.0.1.20171227.tgz && \
    tar -xzf mklml_lnx_2018.0.1.20171227.tgz -C /usr/local/mklml && \
    wget --no-verbose -O - https://github.com/01org/mkl-dnn/archive/v0.12.tar.gz | tar -xzf - && \
    cd mkl-dnn-0.12 && \
    ln -s /usr/local external && \
    mkdir -p build && \
    cd build && \
    cmake .. && \
    make && \
    make install && \
    cd ../.. && \
    rm -rf mkl-dnn-0.12
    
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Protobuf v3.5.1 (for CNTK and others)
RUN wget https://github.com/google/protobuf/releases/download/v3.5.1/protobuf-all-3.5.1.tar.gz && \
    tar -xzf protobuf-all-3.5.1.tar.gz && \
    cd protobuf-3.5.1 && \
    ./autogen.sh && \
    ./configure CFLAGS=-fPIC CXXFLAGS=-fPIC --disable-shared --prefix=/usr/local/protobuf-3.5.1 && \
    make -j $(nproc) && \
    make install

# # Boost (for CNTK) - skipping for now
# RUN wget https://sourceforge.net/projects/boost/files/boost/1.67.0/boost_1_67_0.tar.gz/download && \
#     tar -xzf - && \
#     cd boost_1_67_0 && \
#     ./bootstrap.sh --prefix=/usr/local/boost_1_67_0 && \
#     ./b2 -d0 -j"$(nproc)" install

# # Libzip (for CNTK) - skipping for now
# RUN wget http://nih.at/libzip/libzip-1.1.2.tar.gz && \
#     tar -xzvf ./libzip-1.1.2.tar.gz && \
#     cd libzip-1.1.2 && \
#     ./configure && \
#     make -j all && \
#     make install

# Add admin user (other users can be made admins of jupyterhub from this user)
ARG USER_PW
RUN USER_PW=$USER_PW

# # # Add some more users (to remove windows endings may have to: tr -d '\015' <DOS-file >UNIX-file)
# ADD add_users.sh /
# RUN chmod +x /add_users.sh
# RUN bash -c '. /add_users.sh'

# Configure environment
ENV CONDA_DIR=/user/miniconda3/ \
    SHELL=/bin/bash \
    NB_USER=wonderwoman \
    NB_UID=1000 \
    NB_GID=100 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

# ADD fix-permissions /usr/bin/fix-permissions
# Create users with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN useradd -u $NB_UID -m -s /bin/bash -N $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME && \
    chmod -R 777 $CONDA_DIR
RUN printf "${USER_PW}\n${USER_PW}" | passwd wonderwoman

ENV NB_USER=user1
RUN useradd -m -s /bin/bash -N $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME && \
    chmod -R 777 $CONDA_DIR
RUN printf "${USER_PW}\n${USER_PW}" | passwd $NB_USER

ENV NB_USER=user2
RUN useradd -m -s /bin/bash -N $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME && \
    chmod -R 777 $CONDA_DIR
RUN printf "${USER_PW}\n${USER_PW}" | passwd $NB_USER

ENV NB_USER=user3
RUN useradd -m -s /bin/bash -N $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME && \
    chmod -R 777 $CONDA_DIR
RUN printf "${USER_PW}\n${USER_PW}" | passwd $NB_USER

ENV NB_USER=user4
RUN useradd -m -s /bin/bash -N $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME && \
    chmod -R 777 $CONDA_DIR
RUN printf "${USER_PW}\n${USER_PW}" | passwd $NB_USER

ENV NB_USER=wonderwoman
USER $NB_USER

# Setup work directory for backward-compatibility
RUN mkdir /home/$NB_USER/work && \
    chmod -R 777 /home/$NB_USER

# Install Python (conda) as wonderwoman and check the md5 sum provided on the download site
RUN cd /tmp && \
    curl -O https://repo.continuum.io/miniconda/Miniconda3-4.4.10-Linux-x86_64.sh && \
    /bin/bash Miniconda3-4.4.10-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-4.4.10-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda config --system --prepend channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    $CONDA_DIR/bin/conda config --system --set show_channel_urls true && \
    $CONDA_DIR/bin/conda update --all --quiet --yes && \
    conda clean -tipsy && \
    rm -rf /home/$NB_USER/.cache/yarn

USER root

RUN chmod -R 777 $CONDA_DIR && \
    chmod -R 777 /home/$NB_USER

ENV NB_USER=wonderwoman
USER $NB_USER

# WORKDIR /user

# Create the conda environment
RUN $CONDA_DIR/bin/conda create -n py36

# Tensorflow and Keras
RUN bash -c 'source /user/miniconda3/bin/activate py36 && pip install tensorflow==${TENSORFLOW_VERSION}'
RUN bash -c 'source /user/miniconda3/bin/activate py36 && pip install keras==${KERAS_VERSION}'

# CNTK and Custom Vision Service Python libraries

# RUN bash -c 'source /user/miniconda3/bin/activate py36 && pip install https://cntk.ai/PythonWheel/CPU-Only/cntk-${CNTK_VERSION}.whl'
RUN bash -c 'source /user/miniconda3/bin/activate py36 && pip install cntk==${CNTK_VERSION}'
RUN bash -c 'source /user/miniconda3/bin/activate py36 && pip install azure-cognitiveservices-vision-customvision==0.1.0'

# Other (version-specific) from reequirements files
COPY . .
RUN bash -c 'source /user/miniconda3/bin/activate py36 && pip install -r requirements.txt'
RUN bash -c 'source /user/miniconda3/bin/activate py36 && pip install -r cli-requirements.txt'

# # First try at pytorch install
# RUN bash -c 'source /user/miniconda3/bin/activate py36 && conda install pytorch==${PYTORCH_VERSION} torchvision==${TORCHVISION_VERION} -c pytorch'

# PyTorch
WORKDIR /opt/pytorch
COPY . .

RUN CMAKE_PREFIX_PATH="/user/miniconda3/envs/py36/" && \
    bash -c 'source /user/miniconda3/bin/activate py36 && conda install numpy pyyaml mkl mkl-include setuptools cmake cffi typing' && \
    bash -c 'source /user/miniconda3/bin/activate py36 && conda install pytorch==${PYTORCH_VERSION} torchvision -c pytorch'

# Tensorflow Probability (https://github.com/tensorflow/probability)
RUN bash -c 'source /user/miniconda3/bin/activate py36 && pip install --upgrade tensorflow-probability'

# TF Object Detection API - wip
RUN bash -c 'source /user/miniconda3/bin/activate py36 && pip install Cython'

# Create the conda environment
RUN $CONDA_DIR/bin/conda create -n py35 python=3.5.2 ipykernel

USER root

# Add the py35 kernel to Jupyter
RUN bash -c 'source /user/miniconda3/bin/activate py35 && python -m ipykernel install --name py35 --display-name "Python 3.5.2"'


# Torchvision - this is the development release install path
# RUN bash -c 'source /user/miniconda3/bin/activate py36 && git clone https://github.com/pytorch/vision.git && cd vision && pip install -v .'

### Conda folder permissions ###
RUN chmod -R 777 $CONDA_DIR

### Jupyterhub setup ###

# Additional installs
RUN apt-get install nodejs npm
RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN npm install -g configurable-http-proxy

# Create directories
RUN mkdir -p /etc/init.d/jupyterhub
RUN chmod +x /etc/init.d/jupyterhub
RUN chmod +x /etc/init.d/jupyterhub
RUN mkdir -p /etc/jupyterhub
RUN chmod +x /etc/jupyterhub

# ENV NB_USER=wonderwoman
# USER $NB_USER

# Deal with directory permissions for user and add to userlist
RUN mkdir -p /hub/user/wonderwoman/
RUN chown wonderwoman /hub/user/wonderwoman/
RUN mkdir -p /user/wonderwoman/
RUN chown wonderwoman /user/wonderwoman/
RUN echo "wonderwoman admin" >> /etc/jupyterhub/userlist
RUN chown wonderwoman /etc/jupyterhub
RUN chown wonderwoman /etc/jupyterhub

# Create a default config to /etc/jupyterhub/jupyterhub_config.py
RUN bash -c 'source /user/miniconda3/bin/activate py36 && jupyterhub --generate-config -f /etc/jupyterhub/jupyterhub_config.py'
RUN bash -c 'source /user/miniconda3/bin/activate py36 && echo c.PAMAuthenticator.open_sessions=False >> /etc/jupyterhub/jupyterhub_config.py'
RUN bash -c "source /user/miniconda3/bin/activate py36 && echo c.Authenticator.whitelist={\'wonderwoman\'} >> /etc/jupyterhub/jupyterhub_config.py"
RUN bash -c "source /user/miniconda3/bin/activate py36 && echo c.LocalAuthenticator.create_system_users=True >> /etc/jupyterhub/jupyterhub_config.py"
RUN bash -c "source /user/miniconda3/bin/activate py36 && echo c.Authenticator.admin_users={\'wonderwoman\'} >> /etc/jupyterhub/jupyterhub_config.py"

# Copy TLS certificate and key
ENV SSL_CERT /etc/jupyterhub/secrets/mycert.pem
ENV SSL_KEY /etc/jupyterhub/secrets/mykey.key
COPY ./secrets/*.crt $SSL_CERT
COPY ./secrets/*.key $SSL_KEY
RUN chmod 700 /etc/jupyterhub/secrets && \
    chmod 600 /etc/jupyterhub/secrets/*

# For CNTK (libpython3.6-dev needed)
RUN add-apt-repository ppa:jonathonf/python-3.6 && apt-get update && apt-get install -y libpython3.6-dev

RUN cd /home

CMD bash -c "source /user/miniconda3/bin/activate py36 && jupyterhub -f /etc/jupyterhub/jupyterhub_config.py --JupyterHub.Authenticator.whitelist=\{\'user1\',\'user2\',\'user3\',\'user4\'\} --JupyterHub.hub_ip='' --JupyterHub.ip='' JupyterHub.cookie_secret=bytes.fromhex\('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'\) Spawner.cmd=\['/user/miniconda3/bin/jupyterhub-singleuser'\] --ip '' --port 8788 --ssl-key /etc/jupyterhub/secrets/mykey.key --ssl-cert /etc/jupyterhub/secrets/mycert.pem"
