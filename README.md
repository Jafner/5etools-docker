This is a simple image for hosting your own 5eTools instance. It is based on the Apache `httpd` image and uses a modified version of the auto-updater script from the [5eTools wiki](https://wiki.5e.tools/index.php/5eTools_Install_Guide).

# Usage

## Quickstart
You can quick-start this image by running:
`docker run -d -p 80:80 --name 5etools-docker 5etools-docker`
Then give the container a minute or two to come online and it will be accessible at `localhost`.

## Getting token images
You can configure the container's initialization script to download image files by setting the `IMG` environment variable:
`docker run -d -p 80:80 --name 5etools-docker -e IMG=true 5etools-docker`
This will add a significant amount of time to the container's initialization.

## Using a persistent volume
You can configure the container to use a persistent volume for the server files, either as a Docker-managed volume or by directly mounting a directory on the host file system into the container. Using a persistent volume is required in order to auto-load homebrew. 

### Using a Docker-managed volume
You can persist your container's data by using a Docker-managed volume to preserve data, even if the container is destroyed. To do this, add `-v 5etools_vol:/usr/local/apache2/htdocs` to your run command.

`docker run -d -p 80:80 --name 5etools-docker -v 5etools_vol:/usr/local/apache2/htdocs`

### Using a host directory mapping 
You can alternatively persist your container's data by mapping a directory in the host's file system into the container. To do this, first create two empty directories on the host to map into the container:
`~/5etools-volume$ mkdir htdocs/ htdocs/download`
Both of these directories need to be created for the mapping to work. 
After you've created the empty directories, you can map them into the container with `-v ~/5etools-volume/htdocs:/usr/local/apache2/htdocs`. 
`docker run -d -p 80:80 --name 5etools-docker -v ~/5etools-volume/htdocs:/usr/local/apache2/htdocs 5etools-docker`

## Auto-loading homebrew
It is recommended that you use a host directory mapping if you are going to auto-load homebrew, as the tools for copying files into and out of Docker-managed volumes are more limited. Since this container uses the developer version of the 5eTools server files, homebrew auto-loading is enabled by default. You can configure the homebrew auto-loading as described on the [wiki page](https://wiki.5e.tools/index.php/5eTools_Install_Guide).

## Updating the container
Because this image is built on the auto-updater script, updating the container is very simple. Restart the container with `docker restart 5etools-docker`. When it restarts, the container will automatically check for an update and automatically download it before starting. 

## Integrating a reverse proxy
Supporting integration of a reverse proxy is beyond the scope of this guide. 
However, any instructions which work for the base httpd (Apache) image, should also work for this, as it is minimally different.
