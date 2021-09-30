This is a simple image for hosting your own 5eTools instance. It is based on the Apache `httpd` image and uses a heavily-modified version of the auto-updater script from the [5eTools wiki](https://wiki.5e.tools/index.php/5eTools_Install_Guide). This image is built from [this GitHub repository](https://github.com/Jafner/5etools-docker). 

# Usage

## Default Configuration
You can quick-start this image by running:

```
mkdir -p ~/5etools-docker/htdocs && cd ~/5etools-docker
curl -o docker-compose.yml https://raw.githubusercontent.com/Jafner/5etools-docker/main/docker-compose.yml
docker-compose up -d && docker logs -f 5etools-docker
```

Then give the container a few minutes to come online and it will be accessible at `localhost:8080`.
When you stop the container, it will automatically delete itself. The downloaded files will remain in the `~/5etools-docker/htdocs` directory, so you can always start the container back up by running `docker-compose up -d`.

## Configuring the Setup
The image uses a handful of environment variables to figure out how you want it to run. 
By default, I assume you want to automatically download the latest files from the temporary github mirror. You can configure exactly how you want the script to run with environment variables within the docker-compose file.

### IMG (defaults to true)
When downloading from the `get.5e.tools` structure, grab both the base site files and the image files for the bestiary, items, adventures, etc.. This increases time and bandwidth needed to bring the server up.

### AUTOUPDATE (defaults to true)
Setting this to false bypasses all downloading logic and falls back to the local files if available, or exits if there is no local version.

### DL_TYPE (defaults to github)
This can be set to "get", "github", or "mega". It is used to decide which logic to use to download the source files.

### DL_LINK (defaults to temporary mirror)
This can be set to the URL of the source files you want to use. For a github repository, use the HTTPS link ending with `.git`. For mega, use the full link to the file. For get, use the base domain (e.g. `https://get.5e.tools`), rather than a specific file.


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