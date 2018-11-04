# A Custom Linux VM with JupyterHub for Local or Cloud Deployment

A custom Virtual Machine for Data Science running JupyterHub for multi-tenant Jupyter notebooks. This image can be used stand-alone/locally (CPU or GPU) or deployed as part of the Ubuntu Azure Data Science Virtual Machine (CPU or GPU) to add custom functionality.

The main purpose of this VM is a specialized setup for _computer vision_ tasks.

The ways in which this repo can be used:

* [Local Deployment](#run-locally) (GPU/CPU) with a prebuilt image
* [Cloud Deployment](#azure-cloud-deployment) to Azure
* [Build from a dockerfile](#to-build-the-docker-image-yourself) (GPU/CPU)

The Cloud Deployment runs on top of Azure's Ubuntu Data Science Virtual Machine as a separate instance of JupyterHub which is multitenant and more customized for computer vision tasks.

## Components

**Python 3.5**

Deep Learning:

* TensorFlow 1.12.0 (including Object Detection API)
* PyTorch 0.4.1 or 1.0
* Torchvision 0.2.1
* CNTK 2.6
* Keras 2.1.6

Azure:

* Azure CLI 2.0.22
* Azure ML Python SDK 0.1.68
* Azure Image Search SDK 1.0.0
* Azure Custom Vision Python SDK 0.3.0

Computer Vision Related:

* OpenCV - opencv-python==3.4.3.18
* Scikit-Image - scikit-image==0.13.1
* Imaged Augmentation Library - imgaug==0.2.6
* Shapely for spatial analysis ([Ref](http://shapely.readthedocs.io/en/stable/manual.html)) - Shapely==1.6
* SimpleCV ([Ref](http://simplecv.readthedocs.io/en/1.0/)); can even hook up to webcam etc. - ([Ref](http://simplecv.readthedocs.io/en/1.0/cookbook/#using-a-camera-kinect-or-virtualcamera)) - SimpleCV==1.3
* Dask for external memory bound computation (e.g. digit classification [here](https://github.com/michhar/python-jupyter-notebooks/blob/master/dask/dask-digit-classification.ipynb)) - dask==0.17.2

Other:

* JupyterHub 0.9.4

### Python 3.5 TFP - For Experimenting with Probability Library in TensorFlow

"Python 3.5.2 TFP" (kernel name)

* TensorFlow Probability and TensorFlow nightly build

### Users Set Up on VM

* **5 users**:  tpol, user1, user2, user3, user4
* Password is the one used to build the image.  The default is **"Python3!"**.

See the ARM template (`azuredeploy.json` and `azuredeploy.paramters.json`) for the specs on deploying to Azure.

### Data

* None yet

## Run Locally

Run the docker image locally (**CPU-only**):

* Ensure you have Docker installed (Docker for Windows or Docker for Mac are recommended)
* For CPU, run the following docker `run` command at a command prompt as follows (may need `sudo` to enhance priviledges on Unix systems) (for a command prompt in Windows, search for "cmd"):
 
     `docker run -it -v /var/run/docker.sock:/var/run/docker.sock -p 8788:8788  --ipc-host --expose=8788 rheartpython/cvdeep:latest`

     `docker run -d -p 5555:5555 -p 80:7842 -p 8788:8788 -v ~/dev/:/root/sharedfolder --ipc-host --expose=8788  rheartpython/cvdeep:latest`

* For an Nvidia GPU with Cuda 9.0/cudnn7 (Linux only, as Windows does not support exposing a system Nvidia GPU in docker, yet):

    `sudo nvidia-docker run -it -v /var/run/docker.sock:/var/run/docker.sock -p 8788:8788 --expose=8788 rheartpython/cvdeep_gpu:latest`

### JupyterHub Login

* Log into JupyterHub at https://0.0.0.0:8788 or https://localhost:8788 (note the use of `https`) with the user `tpol` and the system variable password you used when building it (the default specified above) and you should also get an Admin panel to make users Admin as well so they can pip install stuff.

## Azure Cloud Deployment

You can click on the "Deploy to Azure" button to try out the Ubuntu Data Science Virtual Machine with this image running on it (Azure subscription required. Hardware compute [fees](https://azure.microsoft.com/en-us/marketplace/partners/microsoft-ads/linux-data-science-vm/) applies. [Free Trial](https://azure.microsoft.com/free/) available for new customers). 

**IMPORTANT NOTE**: Before you proceed to use the **Deploy to Azure** button you must perform a one-time task to accept the terms of the data science virtual machine on your Azure subscription. You can do this by visiting [Configure Programmatic Deployment](https://ms.portal.azure.com/#blade/Microsoft_Azure_Marketplace/LegalTermsSkuProgrammaticAccessBlade/legalTermsSkuProgrammaticAccessData/%7B%22product%22%3A%7B%22publisherId%22%3A%22microsoft-ads%22%2C%22offerId%22%3A%22linux-data-science-vm%22%2C%22planId%22%3A%22linuxdsvm%22%7D%7D)

### Deployment Options for Azure

| Description | Deploy Here |
| --- | --- |
| CPU DSVM Version | <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmichhar%2Fcustom-azure-dsvm-jupyterhub%2Fmaster%2Fazuredeploy.json" target="_blank"><img src="http://azuredeploy.net/deploybutton.png"/>
</a> |
| GPU DSVM Version (PyTorch 0.4.1) | <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmichhar%2Fcustom-azure-dsvm-jupyterhub%2Fmaster%2Fazuredeploy_gpu_torch0.4.1.json" target="_blank"><img src="http://azuredeploy.net/deploybutton.png"/>
</a> |
| GPU DSVM Version (PyTorch 1.0) | <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmichhar%2Fcustom-azure-dsvm-jupyterhub%2Fmaster%2Fazuredeploy_gpu_torch1.0.json" target="_blank"><img src="http://azuredeploy.net/deploybutton.png"/>
</a> |

### JupyterHub Login

* Log into jupyterhub at `https://<ip or dns name>:8788` (note the use of `https` and port `8788`) with the user `tpol` and the system variable password you used when building it (the default specified above) and you should also get an Admin panel to make the other users Admin as well so they can pip install stuff.
* Note, the DSVM already has a JupyterHub system running at port `8000` if interested.  Check out Azure Portal or Azure Docs for more information on what it contains.

## To Build the Docker Image Yourself

Create the docker image:

1. In the `secrets` folder create some certificate and key files with `openssl` and name them `jupyterhub.crt` and `jupyterhub.key`, respectively.
  * To create these:
  
      `openssl req -new -newkey rsa:2048 -nodes -keyout jupyterhub.key -x509 -days 365 -out jupyterhub.crt`

2. Create a system var called `$USER_PASSWD` with a password for an admin to jupyterhub user.  This will feed into a sys var in the dockerfile/image.  E.g.:

    `export USER_PASSWD=foobar`
    
3. Create the image by running the `docker build` command as follows (name the image tag anything you like, e.g. `rheartpython/cvdeep`, where `rheartpython` is a username on Dockerhub, so use yours or any tag).  Note, on Windows you should run this command in Git Bash ([Download Git for Windodws here](https://git-scm.com/downloads)):

  * CPU:

    `docker build --build-arg USER_PW=$USER_PASSWD -t <dockerhub user>/<image name> -f Linux_py35_CPU.dockerfile .`

  * GPU (nvidia-docker 1.0; build on a machine with this command line tool):

    `nvidia-docker build --build-arg USER_PW=$USER_PASSWD -t <dockerhub user>/<image name> -f Linux_py35_GPU.dockerfile .`

### If You Wish to Push to Dockerhub

 Push the image to Dockerhub so that you and others (namely the VM through the ARM template) can use it  (`docker login` and then `docker push <dockerhub user>/<image name>`).

 ## Credits

 * This work is based on the following projects:
   * Data Science Virtual Machine - https://github.com/Azure/DataScienceVM
   * William Buchwalter's https://github.com/wbuchwalter/deep-learning-bootcamp-vm
   * Ari Bornstein's https://github.com/aribornstein/CVWorkshop

## Contributing

* If you'd like to contribute to this project, fork this repo and make a Pull Request.
* If you see any problems or want a feature, create an Issue.
* Don't panic.
 
