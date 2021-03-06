#!/bin/bash
# based (loosely) on: https://wiki.5e.tools/index.php/5eTools_Install_Guide

cd /usr/local/apache2/htdocs

# this variable can be passed into the environment via docker run or docker-compose
# since this variable is required, I declare it explicitly here
# expects "get", "github", or "mega"
# where "get" refers to the old `get.5e.tools` structure,
# "github" refers to the root of a specific github repository,
# and "mega" refers to a mega.nz download link
# defaults to "github"
DL_TYPE=${DL_TYPE:-github}

# this variable can be passed into the environment via docker run or docker-compose
# since this variable is required, I declare it explicitly here
# expects a URL with the correct content for the DL_TYPE
# defaults to the temporary github mirror
DL_LINK=${DL_LINK:-https://github.com/5etools-mirror-1/5etools-mirror-1.github.io.git}

# this variable can be passed into the environment via docker run or docker-compose
# since this variable is required, I declare it explicitly here
# expects "true" or "false"
# defaults to "true"
AUTOUPDATE=${AUTOUPDATE:-true}

# this variable can be passed into the environment via 
# expects "true" or "false"
# defaults to "false"
IMG=${IMG:-false}


if [ $AUTOUPDATE = false ]; then 
  # if the user doesn't want to update from a source, 
  # check for local version
  # if local version is found, print version and start server
  # if no local version is found, print error message and exit 1
  echo "Auto update disabled. Checking for local version..."
  if [ -f /usr/local/apache2/htdocs/package.json ]; then
    VERSION=$(jq -r .version package.json) # Get version from package.json
    echo " === Starting version $VERSION"
  else
    echo " === No local version detected. Exiting."
    exit 1
  fi
else
  # if the user does want to update from a source,
  # check if url provided via the $DL_LINK env variable is connectable
  echo "Auto update enabled. Checking for remote version..."
  echo " === Checking connection to $DL_LINK..."
  SITE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $DL_LINK)
  if [ $SITE_STATUS = 200 ] || [ $SITE_STATUS = 301 ]; then # if the source URL is reachable
    if [ $DL_TYPE = "get" ]; then # the get.5e.tools structure
      echo " === Using get structure to download from $DL_LINK"
      echo " === WARNING: This part of the script has not yet been tested. Please open an issue on the github if you have trouble."
      # get remote version number
      # takes three steps of wizardry. I did not write this, but it works so I don't touch it.
      FILENAME=`curl -s -k -I $DL_LINK/src/|grep filename|cut -d"=" -f2 | awk '{print $1}'` # returns like "5eTools.1.134.0.zip" (with quotes)
      FILENAME=${FILENAME//[$'\t\r\n"']} # remove quotes, returns like 5eTools.1.134.0.zip
      REMOTE_VERSION=`basename ${FILENAME} ".zip"|sed 's/5eTools\.//'` # get version number, returns like 1.134.0
      if [ "$REMOTE_VERSION" != "$VERSION" ]; then
        echo " === Local version ($VERSION) outdated, updating to $REMOTE_VERSION ..."
        rm ./index.html 2> /dev/null || true
        echo " === Downloading new remote version..."
        mkdir -p ./download
        cd ./download/
        curl --progress-bar -k -O -J $DL_LINK/src/ -C -
        
        if [ "$IMG" = "true" ]; then # download images
          echo " === Downloading images... "
          curl --progress-bar -k -O -J $DL_LINK/img/ -C -
        fi
        
        cd ..

        echo " === Extracting site..."
        7z x ./download/$FILENAME -o./ -y

        if [ "$IMG" = "true" ]; then # extract images
          echo " === Extracting images..."
          7z x ./download/$FILENAME_IMG -o./img -y
          mv ./img/tmp/5et/img/* ./img
          rm -r ./img/tmp
        fi

        echo " === Configuring..." # honestly I don't know enough HTML/CSS/JS to tell exactly what this part of the script does :L
        find . -name \*.html -exec sed -i 's/"width=device-width, initial-scale=1"/"width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no"/' {} \;
        sed -i 's/<head>/<head>\n<link rel="apple-touch-icon" href="icon\/icon-512.png">/' index.html
        sed -i 's/navigator.serviceWorker.register("\/sw.js/navigator.serviceWorker.register("sw.js/' index.html
        sed -i 's/navigator.serviceWorker.register("\/sw.js/navigator.serviceWorker.register("sw.js/' 5etools.html

        echo " === Cleaning up downloads"
        find ./download/ -type f ! -name "*.${VER}.zip" -exec rm {} + # delete the downloaded zip files

        echo " === Done!"
      else
        echo " === Local version matches remote, no action."
      fi 
      VERSION=$(jq -r .version package.json) # Get version from package.json
      echo " === Starting version $VERSION"
      httpd-foreground
    elif [ $DL_TYPE = "github" ]; then # the github structure
      echo " === Using GitHub structure to update from $DL_LINK"
      echo " === Warning: images will be downloaded automatically, which will take longer"
      if [ ! -d "./.git" ]; then # if no git repository already exists
        git config --global user.email "autodeploy@jafner.tools"
        git config --global user.name "AutoDeploy"
        git init > /dev/null 2>&1
        git add . > /dev/null
        git commit -m "Init" > /dev/null
        git remote add upstream $DL_LINK
      fi
      echo " === Pulling from GitHub... (This might take a while)"
      git pull --depth=1 upstream master 2> /dev/null
      VERSION=$(jq -r .version package.json) # Get version from package.json
      echo " === Starting version $VERSION"
      httpd-foreground
    elif [ $DL_TYPE = "mega" ]; then # the mega structure
      echo " === Using mega structure to download from $DL_LINK"
      echo " === Warning: This method will overwrite the current local version because it cannot check the remote version"
      echo " === Warning: This method ignores the IMG environment variable."
      # downloading files
      mkdir -p ./download
      megadl --path ./download/ --no-progress --print-names $DL_LINK > filename # downloads the file to ./download/ and redirects the filename to a file called filename
      FILENAME=$(cat filename) 
      rm filename

      # extracting files
      echo " === Extracting site..."
      7z x ./download/$FILENAME -o./ -y

      # configuring the index.html and 5etools.html files
      echo " === Configuring..." # honestly I don't know enough HTML/CSS/JS to tell exactly what this part of the script does :L
      find . -name \*.html -exec sed -i 's/"width=device-width, initial-scale=1"/"width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no"/' {} \;
      sed -i 's/<head>/<head>\n<link rel="apple-touch-icon" href="icon\/icon-512.png">/' index.html
      sed -i 's/navigator.serviceWorker.register("\/sw.js/navigator.serviceWorker.register("sw.js/' index.html
      sed -i 's/navigator.serviceWorker.register("\/sw.js/navigator.serviceWorker.register("sw.js/' 5etools.html

      # cleaning up downloads
      echo " === Cleaning up downloads"
      find ./download/ -type f ! -name "*.${VER}.zip" -exec rm {} + # delete the downloaded zip files

      # starting the server
      VERSION=$(jq -r .version package.json) # Get version from package.json
      echo " === Starting version $VERSION"
      httpd-foreground
    else # if the DL_TYPE env var is not recognized
      echo " === Could not determine download structure."
      if [ -f /usr/local/apache2/htdocs/package.json ]; then
        VERSION=$(jq -r .version package.json) # Get version from package.json
        echo " === Falling back to local version: $VERSION"
        httpd-foreground
      else
        echo " === No local version found! You must be able to access $DL_LINK to grab the 5eTools files."
        echo " === Hint: Make sure you have the correct DL_TYPE environment variable set."
        exit 1
      fi
    fi
  else # if the download source is not accessible
    echo " === Could not connect to $DL_LINK"
    if [ -f /usr/local/apache2/htdocs/package.json ]; then
      VERSION=$(jq -r .version package.json) # Get version from package.json
      echo " === Falling back to local version: $VERSION"
      httpd-foreground
    else
      echo " === No local version found! You must be able to access $DL_LINK to grab the 5eTools files."
      echo " === Hint: Make sure you have the correct DL_TYPE environment variable set."
      exit 1
    fi
  fi
fi
