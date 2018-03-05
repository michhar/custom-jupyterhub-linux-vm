# custom-azure-dsvm-jupyterhub

A custom Data Science Virtual Machine deployment setup with template.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmichhar%2Fcustom-azure-dsvm-jupyterhub%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

ARM template instructions coming soon.

## To Build and Test the Docker Image

Create the docker image:

* In the `secrets` folder create some certificate and key files with `openssl` and name them `jupyterhub.crt` and `jupyterhub.key`, respectively.
  * To create these:
  
      `openssl req \
        -newkey rsa:2048 -nodes -keyout domain.key \
        -x509 -days 365 -out domain.crt`

* Create a system var called `$USER_PASSWD` with a password for an admin to jupyterhub user.  This will feed into a sys var in the dockerfile/image.  E.g.:

    `export USER_PASSWD=foobar`
    
* Run docker build command as follows (name the image anything you like, here it's `rheartpython/cvworkshop` where `rheartpython` is the user name of mine on Dockerhub):

    `docker build --build-arg USER_PW=$USER_PASSWD -t rheartpython/cvworkshop .`

Run the docker image locally (on a Unix-based system):

* Run docker run command as follows:
 
     `sudo docker run -it -v /var/run/docker.sock:/var/run/docker.sock -p 8000:8000 --expose=8000 rheartpython/cvworkshop`
     
 * Log into jupyterhub at https://0.0.0.0:8000 with the user `wonderwoman` and the system variable password you used and you should also get an Admin panel to add more users to the jupyterhub.
 
 Push the image to Dockerhub so that you and others (namely the VM through the ARM template) can use it.
