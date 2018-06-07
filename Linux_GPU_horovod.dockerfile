FROM nvidia/cuda:9.0-devel-ubuntu16.04

# TensorFlow version is tightly coupled to CUDA and cuDNN so it should be selected carefully
ENV TENSORFLOW_VERSION=1.8.0
ENV PYTORCH_VERSION=0.4.0
ENV CUDNN_VERSION=7.0.5.15-1+cuda9.0
ENV NCCL_VERSION=2.2.12-1+cuda9.0

# Python 2.7 or 3.5 is supported by Ubuntu Xenial out of the box
ARG python=3.5
ENV PYTHON_VERSION=${python}

RUN echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        curl \
        vim \
        wget \
        ca-certificates \
        libcudnn7=${CUDNN_VERSION} \
        libnccl2=${NCCL_VERSION} \
        libnccl-dev=${NCCL_VERSION} \
        libjpeg-dev \
        libpng-dev \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev

# For opencv
RUN apt-get update && apt-get install -y libsm6 libxext6 libxrender-dev

RUN ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

# Add admin user (other users can be made admins of jupyterhub from this user)
ARG USER_PW
RUN USER_PW=$USER_PW

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

# Add user to sudoers file
RUN echo "wonderwoman ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

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

ENV NB_USER=wonderwoman
USER $NB_USER

# Create the conda environment and add a few scientific packages
RUN $CONDA_DIR/bin/conda create -n py35 python=3.5.2 ipykernel jupyterhub Cython numpy matplotlib scipy scikit-learn

USER root

# Install TensorFlow and Keras
RUN bash -c 'source /user/miniconda3/bin/activate py35 && python -m pip install tensorflow-gpu==${TENSORFLOW_VERSION} keras h5py'

# Install PyTorch
RUN PY=$(echo ${PYTHON_VERSION} | sed s/\\.//); \
    if [[ ${PYTHON_VERSION} == 3* ]]; then \
        bash -c 'source /user/miniconda3/bin/activate py35 && python -m pip install http://download.pytorch.org/whl/cu90/torch-${PYTORCH_VERSION}-cp${PY}-cp${PY}m-linux_x86_64.whl'; \
    else \
        bash -c 'source /user/miniconda3/bin/activate py35 && python -m pip install http://download.pytorch.org/whl/cu90/torch-${PYTORCH_VERSION}-cp${PY}-cp${PY}mu-linux_x86_64.whl'; \
    fi; \
    bash -c 'source /user/miniconda3/bin/activate py35 && python -m pip install torchvision'

# Install Open MPI
RUN mkdir /tmp/openmpi && \
    cd /tmp/openmpi && \
    wget https://www.open-mpi.org/software/ompi/v3.0/downloads/openmpi-3.0.0.tar.gz && \
    tar zxf openmpi-3.0.0.tar.gz && \
    cd openmpi-3.0.0 && \
    ./configure --enable-orterun-prefix-by-default && \
    make -j $(nproc) all && \
    make install && \
    ldconfig && \
    rm -rf /tmp/openmpi

# Install Horovod, temporarily using CUDA stubs
RUN ldconfig /usr/local/cuda-9.0/targets/x86_64-linux/lib/stubs && \
    bash -c 'source /user/miniconda3/bin/activate py35 && HOROVOD_GPU_ALLREDUCE=NCCL HOROVOD_WITH_TENSORFLOW=1 HOROVOD_WITH_PYTORCH=1 python -m pip install --no-cache-dir horovod' && \
    ldconfig

RUN chmod -R 777 $CONDA_DIR && \
    chmod -R 777 /home/$NB_USER

# Create a wrapper for OpenMPI to allow running as root by default
RUN mv /usr/local/bin/mpirun /usr/local/bin/mpirun.real && \
    echo '#!/bin/bash' > /usr/local/bin/mpirun && \
    echo 'mpirun.real --allow-run-as-root "$@"' >> /usr/local/bin/mpirun && \
    chmod a+x /usr/local/bin/mpirun

# Configure OpenMPI to run good defaults:
#   --bind-to none --map-by slot --mca btl_tcp_if_exclude lo,docker0
RUN echo "hwloc_base_binding_policy = none" >> /usr/local/etc/openmpi-mca-params.conf && \
    echo "rmaps_base_mapping_policy = slot" >> /usr/local/etc/openmpi-mca-params.conf && \
    echo "btl_tcp_if_exclude = lo,docker0" >> /usr/local/etc/openmpi-mca-params.conf

# Set default NCCL parameters
RUN echo NCCL_DEBUG=INFO >> /etc/nccl.conf && \
    echo NCCL_SOCKET_IFNAME=^docker0 >> /etc/nccl.conf

# Install OpenSSH for MPI to communicate between containers
RUN apt-get install -y --no-install-recommends openssh-client openssh-server && \
    mkdir -p /var/run/sshd

# Allow OpenSSH to talk to containers without asking for confirmation
RUN cat /etc/ssh/ssh_config | grep -v StrictHostKeyChecking > /etc/ssh/ssh_config.new && \
    echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config.new && \
    mv /etc/ssh/ssh_config.new /etc/ssh/ssh_config

# Download examples
RUN apt-get install -y --no-install-recommends subversion && \
    svn checkout https://github.com/uber/horovod/trunk/examples && \
    rm -rf /examples/.svn

WORKDIR "/examples"
COPY . .

# Install general packages from a requirements file
RUN bash -c 'source /user/miniconda3/bin/activate py35 && pip install -r requirements.txt'

# Add the py35 kernel to Jupyter
RUN bash -c 'source /user/miniconda3/bin/activate py35 && python -m ipykernel install --name py35 --display-name "Python 3.5.2"'


### Jupyterhub setup ###

USER root

# Additional installs
RUN apt-get update && apt-get install -y nodejs npm
RUN ln -s /usr/bin/nodejs /usr/bin/node
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
RUN bash -c 'source /user/miniconda3/bin/activate py35 && jupyterhub --generate-config -f /etc/jupyterhub/jupyterhub_config.py'
RUN bash -c 'source /user/miniconda3/bin/activate py35 && echo c.PAMAuthenticator.open_sessions=False >> /etc/jupyterhub/jupyterhub_config.py'
RUN bash -c "source /user/miniconda3/bin/activate py35 && echo c.Authenticator.whitelist={\'wonderwoman\'} >> /etc/jupyterhub/jupyterhub_config.py"
RUN bash -c "source /user/miniconda3/bin/activate py35 && echo c.LocalAuthenticator.create_system_users=True >> /etc/jupyterhub/jupyterhub_config.py"
RUN bash -c "source /user/miniconda3/bin/activate py35 && echo c.Authenticator.admin_users={\'wonderwoman\'} >> /etc/jupyterhub/jupyterhub_config.py"

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

# For CNTK (libpython3.6-dev needed) if using Pythohn 3.6
# RUN add-apt-repository ppa:jonathonf/python-3.6 && apt-get update && apt-get install -y libpython3.6-dev

RUN cd /home

CMD bash -c "source /user/miniconda3/bin/activate py35 && jupyterhub -f /etc/jupyterhub/jupyterhub_config.py --JupyterHub.Authenticator.whitelist=\{\'user1\',\'user2\',\'user3\',\'user4\'\} --JupyterHub.hub_ip='' --JupyterHub.ip='' JupyterHub.cookie_secret=bytes.fromhex\('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'\) Spawner.cmd=\['/user/miniconda3/bin/jupyterhub-singleuser'\] --ip '' --port 8788 --ssl-key /etc/jupyterhub/secrets/mykey.key --ssl-cert /etc/jupyterhub/secrets/mycert.pem"
