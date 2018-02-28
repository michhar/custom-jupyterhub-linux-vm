# custom-azure-dsvm-jupyterhub
A custom VM config

ARM template instructions coming soon.

## To Test the Docker Image

Create the docker image:

* In the `secrets` folder create some certificate and key files with `openssl` and name them `jupyterhub.crt` and `jupyterhub.key`, respectively.
* Create a system var called `$USER_PASSWD` with a password for an admin to jupyterhub user.  This will feed into a sys var in the dockerfile/image.
* Run docker build command as follows (name the image anything you like, here it's `rheartpython/cvworkshop`):

    `docker build --build-arg USER_PW=$USER_PASSWD -t rheartpython/cvworkshop .`

Run the docker image locally:

* Run docker run command as follows:
 
     `sudo docker run -it -v /var/run/docker.sock:/var/run/docker.sock -p 8000:8000 --expose=8000 rheartpython/cvworkshop`
     
 * Log into jupyterhub at https://0.0.0.0:8000 with the user `wonderwoman` and the system variable password you used.
 
 Push the image to Dockerhub so that you and others (namely the VM through the ARM template) can use it.
