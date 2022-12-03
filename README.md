This is a simple image for hosting your own 5eTools instance. It is based on the Apache `httpd` image and uses components of the auto-updater script from the [5eTools wiki](https://wiki.5e.tools/index.php/5eTools_Install_Guide). This image is built from [this GitHub repository](https://github.com/Jafner/5etools-docker). 

# Usage
Below we talk about how to install and configure the container. 

## Default Configuration
You can quick-start this image by running:

```
mkdir -p ~/5etools-docker/htdocs && cd ~/5etools-docker
curl -o docker-compose.yml https://raw.githubusercontent.com/Jafner/5etools-docker/main/docker-compose.yml
docker-compose up -d && docker logs -f 5etools-docker
```

Then give the container a few minutes to come online (it takes a while to pull the Github repository) and it will be accessible at `localhost:8080`.
When you stop the container, it will automatically delete itself. The downloaded files will remain in the `~/5etools-docker/htdocs` directory, so you can always start the container back up by running `docker-compose up -d`.

## Volume Mapping
By default, I assume you want to keep downloaded files, even if the container dies. And you want the downloaded files to be located at `~/5etools-docker/htdocs`.  

If you want the files to be located somewhere else on your system, change the left side of the volume mapping. For example, if I wanted to keep my files at `~/data/docker/5etools`, the volume mapping would be:

```
    volumes:
      - ~/data/docker/5etools:/usr/local/apache2/htdocs
```

Alternatively, you can have Docker or Compose manage your volume. (This makes adding homebrew practically impossible.)  

Use a Compose-managed volume with:
```
...
    volumes:
      - 5etools-docker:/usr/local/apache2/htdocs
...
volumes:
  5etools-docker:
```

Or have the Docker engine manage the volume (as opposed to Compose). First, create the volume with `docker volume create 5etools-docker`, then add the following to your `docker-compose.yml`:
```
...
    volumes:
      - 5etools-docker:/usr/local/apache2/htdocs
...
volumes:
  5etools-docker:
    external: true
```

## Environment Variables
The image uses environment variables to figure out how you want it to run. 
By default, I assume you want to automatically download the latest files from the Github mirror. Use the environment variables in the `docker-compose.yml` file to configure things.

### SOURCE (defaults to GITHUB-NOIMG)
Required unless OFFLINE_MODE=TRUE.
Expects one of "GITHUB", "GITHUB-NOIMG", "GET5ETOOLS", or "GET5ETOOLS-NOIMG". Where:  
  > "GITHUB" pulls from https://github.com/5etools-mirror-1/5etools-mirror-1  
  > "GITHUB-NOIMG" pulls from https://github.com/5etools-mirror-1/5etools-mirror-1 without image files.  
  > "GET5ETOOLS" pulls from https://get.5e.tools  
  > "GET5ETOOLS-NOIMG" pulls from https://get.5e.tools without image files.  

The get.5e.tools source has been down (redirecting to 5e.tools) during development. This method is not tested.  

**Note: As of December 2022, get.5e.tools has been down for several months**. The URL redirects to the main 5etools page, but does not provide packaged archives of the site like it used to. I will update this if or when the original get.5e.tools returns.

### OFFLINE_MODE
Optional. Expects "TRUE" to enable. 
Setting this to true tells the server to run from the local files if available, or exits if there is no local version. 

### PUID and PGID
During the image build process, we set the owner of the `htdocs` directory to `1000:1000` by default. If you need a different UID and GID to own the files, you can build the image from the source Dockerfile and pass the PUID and PGID variables as desired.

## Integrating a reverse proxy
Supporting integration of a reverse proxy is beyond the scope of this guide. 
However, any instructions which work for the base `httpd` (Apache) image, should also work for this, as it is minimally different.

# Auto-loading homebrew
To use auto-loading homebrew, you will need to use a host directory mapping as described above. 

1. Online the container and wait for the container to finish starting. You can monitor its progress with `docker logs -f 5etools-docker`.
2. Assuming you are using the mapping `~/5etools-docker/htdocs:/usr/local/apache2/htdocs` place your homebrew json files into the `~/5etools-docker/htdocs/homebrew/` folder, then add their filenames to the `~/5etools-docker/htdocs/homebrew/index.json` file.
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
See the [wiki page](https://wiki.5e.tools/index.php/5eTools_Install_Guide) for more information. 