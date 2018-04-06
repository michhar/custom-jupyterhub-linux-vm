# A Custom Azure Linux VM with JupyterHub

A custom Data Science Virtual Machine deployment setup with template.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmichhar%2Fcustom-azure-dsvm-jupyterhub%2Fmaster%2Fazuredeploy_dsvmbase.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

## Components

Python:

* Python 3.6 (Anaconda release)
* JupyterHub 1.7.2

Deep Learning:

* TensorFlow 1.6.0
* PyTorch 0.3.0.post4-cp36
* CNTK 2.4

Other:

* Custom Vision Python SDK - latest

Users:

* 5 users:  wonderwoman, user1, user2, user3, user4
* Password is the one used to build the image.  The default is "cheese".

See the ARM template (`azuredeploy.json` and `azuredeploy.paramters.json`) for the specs on deploying to Azure.

## To build the Docker image

Create the docker image:

* In the `secrets` folder create some certificate and key files with `openssl` and name them `jupyterhub.crt` and `jupyterhub.key`, respectively.
  * To create these:
  
      `openssl req -new -newkey rsa:2048 -nodes -keyout jupyterhub.key -x509 -days 365 -out jupyterhub.crt`

* Create a system var called `$USER_PASSWD` with a password for an admin to jupyterhub user.  This will feed into a sys var in the dockerfile/image.  E.g.:

    `export USER_PASSWD=foobar`
    
* Run docker build command as follows (name the image anything you like, here it's `rheartpython/cvopenhack` where `rheartpython` is the user name of mine on Dockerhub).  Note, on Windows it is recommended to run this command in Git Bash ([Download Git for Windodws here](https://git-scm.com/downloads)):

    `docker build --build-arg USER_PW=$USER_PASSWD -t rheartpython/cvopenhack -f ForUnix_py36.dockerfile .`

 Push the image to Dockerhub so that you and others (namely the VM through the ARM template) can use it.

## Run the image as a Jupyterhub system

Run the docker image locally (on a Unix-based system):

* Ensure you have Docker installed (Docker for Windows or Docker for Mac are recommended)
* Run the following docker `run` command at a command prompt as follows (may need `sudo` to enhance priviledges on Unix systems) (for a command prompt in Windows, search for "cmd"):
 
     `docker run -it -v /var/run/docker.sock:/var/run/docker.sock -p 8788:8788 --expose=8788 rheartpython/cvopenhack:latest`
     
 * Log into jupyterhub at https://0.0.0.0:8788 or https://localhost:8788 with the user `wonderwoman` and the system variable password you used when building it and you should also get an Admin panel to add more users to the jupyterhub or make them Admin as well so they can install stuff.

 ## Credits

 * This work is based on the following projects:
   * Data Science Virtual Machine - https://github.com/Azure/DataScienceVM
   * William Buchwalter's https://github.com/wbuchwalter/deep-learning-bootcamp-vm
   * Ari Bornstein's https://github.com/aribornstein/CVWorkshop

## Contributing

* If you'd like to contribute to this project, fork this repo and make a Pull Request.
* If you see an problems or want a feature, open an Issue.
* Don't panic.
 
