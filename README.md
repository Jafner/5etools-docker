This is a simple image for hosting your own 5eTools instance. It is based on the Apache `httpd` image and uses a modified version of the auto-updater script from the [5eTools wiki](https://wiki.5e.tools/index.php/5eTools_Install_Guide).

# Usage with Docker Run

## Quickstart
You can quick-start this image by running:
`docker run -d -p 80:80 --rm --name 5etools-docker jafner/5etools-docker`
Then give the container a minute or two to come online and it will be accessible at `localhost`.
This is what each part of that command does:
```
docker run \ # this is the basic docker command to start a docker container from a given image
-d \ # this is the 'daemon' flag, which allows the container to run in the background
-p 80:80 \ # this is the port flag which maps port 80 on the host to port 80 inside the container. You can change the host port mapping to something else (such as 8080) if you already have something running on port 80.
--rm \ # this is the remove flag, it tells docker to delete the container when it stops running. This is an option for portability.
--name 5etools-docker \ # this tells docker to set the name of the new container to 5etools-docker, rather than auto-generate a name. You can change this to whatever you like.
jafner/5etools-docker # this is the docker image you want to run. jafner is the repository and 5etools-docker is the specific image. 
```

### Getting token images
You can configure the container's initialization script to download image files by setting the `IMG` environment variable:
`docker run -d -p 80:80 --rm --name 5etools-docker -e IMG=true 5etools-docker`
This will add a significant amount of time to the container's initialization.
The `-e` flag specifies a Docker environment variable, which is passed into the container's shell environment and allows for customization of the container during the run command. Here, the environment variable is named `IMG` and this command sets the value to `true`.

### Using a persistent volume
You can configure the container to use a persistent volume for the server files, either as a Docker-managed volume or by directly mounting a directory on the host file system into the container. Using a persistent volume is required in order to auto-load homebrew. 

#### Using a Docker-managed volume
You can persist your container's data by using a Docker-managed volume to preserve data, even if the container is destroyed. To do this, add `-v 5etools_vol:/usr/local/apache2/htdocs` to your run command.

`docker run -d -p 80:80 --name 5etools-docker -v 5etools_vol:/usr/local/apache2/htdocs`

#### Using a host directory mapping 
You can alternatively persist your container's data by mapping a directory in the host's file system into the container. To do this, first create two empty directories on the host to map into the container:
`~/docker/5etools-docker$ mkdir htdocs/ htdocs/download`
Both of these directories need to be created for the mapping to work. 
After you've created the empty directories, you can map them into the container with `-v ~/5etools-docker/htdocs:/usr/local/apache2/htdocs`. 
`docker run -d -p 80:80 --name 5etools-docker -v ~/docker/5etools-docker/htdocs:/usr/local/apache2/htdocs 5etools-docker`
Note: host directory mappings must be absolute (cannot use `.` to refer to working directory). However, you can still refer to your working directory with `-v ${PWD}/htdocs:/usr/local/apache2/htdocs` where `${PWD}` runs the pwd (print working directory) command and passes it into the mapping. 

### Auto-loading homebrew
To set up auto-loading homebrew, first create an empty `homebrew/` folder in the directory you would like to use for 5etools-docker. For example `~/docker/5etools-docker/htdocs/homebrew`. Then, run the docker container with `-v ~/docker/5etools-docker/htdocs/homebrew:/usr/local/apache2/htdocs/homebrew`. If you are already using a host directory mapping of `-v ~/docker/5etools-docker/htdocs:/usr/local/apache2/htdocs` then this is unnecessary. 
You can configure the homebrew auto-loading as described on the [wiki page](https://wiki.5e.tools/index.php/5eTools_Install_Guide). You will need to download the json files for the homebrew you would like to auto-load and place them into the `homebrew/` directory, then add the filenames to `homebrew/index.json`. 

### Updating the container
Because this image is built on the auto-updater script, updating the container is very simple. Restart the container with `docker restart 5etools-docker`. When it restarts, the container will automatically check for an update and automatically download it before starting. This is true regardless of whether the container is configured to use a persistent volume. 
Note: there is no way to disable this auto-updating behavior except to never restart the container. If you want a specific version of the container, it is recommended that you use the `httpd` image instead.

### Integrating a reverse proxy
Supporting integration of a reverse proxy is beyond the scope of this guide. 
However, any instructions which work for the base `httpd` (Apache) image, should also work for this, as it is minimally different.

# Usage with Docker Compose
Create a `docker-compose.yml` file with the following contents:

```yml
version: '3'
services:
  5etools:
  	image: jafner/5etools-docker
  	container_name: 5etools
  	volumes:
  	  - 5etools_vol:/usr/local/apache2/htdocs
  	ports:
  	  - 8080:80
volumes:
  5etools_vol:
```

This version has a persistent Docker-managed volume. If you would like to auto-load homebrew, see the section below.

## Docker Compose with auto-loading homebrew
You will need to do a little prep on your host before starting the Docker Compose stack. 
Assuming you want to use the directory `~/5etools-docker` on the host:

1. Create the directories with `mkdir ~/5etools-docker ~/5etools-docker/htdocs ~/5etools-docker/htdocs/download`.
2. Create the `~/5etools-docker/docker-compose.yml` file with your preferred text editor.
3. Add the following contents:

```yml
version: '3'
services:
  5etools:
  	image: jafner/5etools-docker
  	container_name: 5etools
  	volumes:
  	  - ~/5etools-docker/htdocs:/usr/local/apache2/htdocs
  	ports:
  	  - 8080:80
```

4. Bring up the stack with `docker-compose -f ~/5etools-docker/docker-compose.yml up -d` and wait for the container to finish starting. You can monitor its progress with `docker logs -f 5etools`.
5. Once the stack is online, you will need to download the json files for the homebrew you would like to auto-load and place them into the `~/5etools-docker/htdocs/homebrew/` folder, then add each filename to the `toImport:` array within `homebrew/index.json`.
For example, if your homebrew folder contains:
```
index.json
'Jafner; JafnerBrew Campaigns.json'
'Jafner; JafnerBrew Collection.json'
'Jafner; Legendary Tomes of Knowledge.json'
'KibblesTasty; Artificer (Revised).json'
```
Then your `index.json` should look like:
```json
{
    "readme": [
        "NOTE: This feature is designed for use in user-hosted copies of the site, and not for integrating \"official\" 5etools content.",
        "The \"production\" version of the site (i.e., not the development ZIP) has this feature disabled. You can re-enable it by replacing `IS_DEPLOYED = \"X.Y.Z\";` in the file `js/utils.js`, with `IS_DEPLOYED = undefined;`",
        "This file contains as an index for other homebrew files, which should be placed in the same directory.",
        "For example, add \"My Homebrew.json\" to the \"toImport\" array below, and have a valid JSON homebrew file in this (\"homebrew/\") directory."
    ],
    "toImport": [
        "Jafner; JafnerBrew Collection.json",
        "Jafner; JafnerBrew Campaigns.json",
        "Jafner; Legendary Tomes of Knowledge.json",
        "KibblesTasty; Artificer (Revised).json"
    ]
}
```
Note the commas after each entry except the last in each array.