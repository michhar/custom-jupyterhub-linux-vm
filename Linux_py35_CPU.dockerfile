############################################
# For an Ubuntu Deep Learning frameworks environment
# running Jupyterhub.
#
# Build with the following:
#  docker build --build-arg USER_PW=$USER_PASSWD -t <dockerhub username>/<image name> -f Linux_py36.dockerfile .
#
# Run with:
# docker run -it -v /var/run/docker.sock:/var/run/docker.sock -p 8788:8788 --expose=8788 <dockerhub username>/<image name>
# 
# Log in to Jupyterhub at https://localhost:8788 with
# password specified in the environment variable
# $USER_PASSWD and username wonderwoman.
############################################

FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04

LABEL maintainer "Micheleen Harris (contact michhar <at> microsoft.com)"
ENV TENSORFLOW_VERSION="1.12.0"
ENV KERAS_VERSION="2.2.4"
ENV PYTORCH_VERSION="1.0"
ENV TORCHVISION_VERSION="0.1.6"

RUN apt-get update && apt-get install -y \
    apt-transport-https \
    software-properties-common \
    nodejs \
    npm \
    zip \
    sudo \
    libsm6 \
    libxext6

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

# For Azure CLI

RUN apt-get update && apt-get install apt-transport-https lsb-release software-properties-common dirmngr -y

RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/azure-cli.list

RUN apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv \
     --keyserver packages.microsoft.com \
     --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF && \
     apt-get update && \
     apt-get install azure-cli

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

USER root

# To install new kernels
RUN $CONDA_DIR/bin/pip install ipykernel

# Create the conda environment
RUN $CONDA_DIR/bin/conda create -n py352 python=3.5.2 ipykernel

# Tensorflow and Keras
RUN $CONDA_DIR/envs/py352/bin/pip install tensorflow==${TENSORFLOW_VERSION}
RUN $CONDA_DIR/envs/py352/bin/pip install keras==${KERAS_VERSION}

# PyTorch
RUN $CONDA_DIR/envs/py352/bin/pip install torch==${PYTORCH_VERSION} torchvision==${TORCHVISION_VERSION}

# Requirements into the Python 3.5.2 - other useful computer vision related libs
COPY requirements.txt .
RUN $CONDA_DIR/envs/py352/bin/pip install -r requirements.txt

# # TF Object Detection API - wip
# RUN bash -c 'source /user/miniconda3/bin/activate py36 && pip install Cython'

# Create the conda environment for TensorFlow Probability and stats use (Python 3.5 as well)
RUN $CONDA_DIR/bin/conda create -n py35_tfp python=3.5.2 ipykernel

# Installing a Probability lib into Conda env py35_tfp:
# Tensorflow Probability (https://github.com/tensorflow/probability) - experimental (in its own conda env)
# - depends on a nightly build of TensorFlow
RUN $CONDA_DIR/envs/py35_tfp/bin/pip install tensorflow==${TENSORFLOW_VERSION}
RUN $CONDA_DIR/envs/py35_tfp/bin/pip install --upgrade tensorflow-probability

# CoreML converter and validation tools for models
RUN git clone https://github.com/apple/coremltools.git && cd coremltools && $CONDA_DIR/envs/py352/bin/pip install -v .

# Add the Pythons (TensorFlow Probability) kernel to Jupyter
RUN $CONDA_DIR/envs/py352/bin/python -m ipykernel install --name py352 --display-name "Python 3.5.2 Custom"
RUN $CONDA_DIR/envs/py35_tfp/bin/python -m ipykernel install --name py35_tfp --display-name "Python 3.5 TFP"

# Configure jupyter nbextensions (needed as in https://github.com/jupyter-widgets/ipywidgets/issues/1702#issuecomment-332392774)
RUN $CONDA_DIR/bin/pip install jupyter jupyterhub notebook pyzmq
RUN $CONDA_DIR/bin/conda install -c conda-forge jupyter_contrib_nbextensions ipywidgets
RUN $CONDA_DIR/bin/jupyter contrib nbextension install --sys-prefix
RUN $CONDA_DIR/bin/jupyter nbextension enable --py --sys-prefix widgetsnbextension

### Conda folder permissions ###
# - must do as root, but gives permission so can pip install etc.
USER root

RUN chmod -R 777 $CONDA_DIR

### Jupyterhub setup ###

# Additional configuring
# Using Ubuntu
RUN curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash - &&\
    sudo apt-get install -y nodejs

RUN npm install -g configurable-http-proxy

# Create directories
RUN mkdir -p /etc/init.d/jupyterhub
RUN chmod +x /etc/init.d/jupyterhub
RUN chmod +x /etc/init.d/jupyterhub
RUN mkdir -p /etc/jupyterhub
RUN chmod +x /etc/jupyterhub

# Deal with directory permissions for user and add to userlist
RUN mkdir -p /hub/user/wonderwoman/
RUN chown wonderwoman /hub/user/wonderwoman/
RUN mkdir -p /user/wonderwoman/
RUN chown wonderwoman /user/wonderwoman/
RUN echo "wonderwoman admin" >> /etc/jupyterhub/userlist
RUN chown wonderwoman /etc/jupyterhub
RUN chown wonderwoman /etc/jupyterhub

# Create a default config to /etc/jupyterhub/jupyterhub_config.py
RUN jupyterhub --generate-config -f /etc/jupyterhub/jupyterhub_config.py
RUN echo "c.PAMAuthenticator.open_sessions=False" >> /etc/jupyterhub/jupyterhub_config.py
RUN echo "c.Authenticator.whitelist={'wonderwoman'}" >> /etc/jupyterhub/jupyterhub_config.py
RUN echo "c.LocalAuthenticator.create_system_users=True" >> /etc/jupyterhub/jupyterhub_config.py
RUN echo "c.Authenticator.admin_users={'wonderwoman'}" >> /etc/jupyterhub/jupyterhub_config.py

# Copy TLS certificate and key
ENV SSL_CERT /etc/jupyterhub/secrets/mycert.pem
ENV SSL_KEY /etc/jupyterhub/secrets/mykey.key
COPY ./secrets/*.crt $SSL_CERT
COPY ./secrets/*.key $SSL_KEY
RUN chmod 700 /etc/jupyterhub/secrets && \
    chmod 600 /etc/jupyterhub/secrets/*

# Creating a file directory for files to spawn to all users - testing this
# c.Spawner.notebook_dir = '~/files' # could be a good place to place tf models
ENV USER_FILES_DIR /etc/jupyterhub/files
RUN mkdir $USER_FILES_DIR &&\
    cd $USER_FILES_DIR

RUN cd /home

CMD bash -c "jupyterhub -f /etc/jupyterhub/jupyterhub_config.py --JupyterHub.Authenticator.whitelist=\{\'wonderwoman\',\'user1\',\'user2\',\'user3\',\'user4\'\} --JupyterHub.hub_ip='' --JupyterHub.ip='' JupyterHub.cookie_secret=bytes.fromhex\('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'\) Spawner.cmd=\['jupyterhub-singleuser'\] --ip '' --port 8788 --ssl-key /etc/jupyterhub/secrets/mykey.key --ssl-cert /etc/jupyterhub/secrets/mycert.pem"
