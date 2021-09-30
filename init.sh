#!/bin/bash
# based (loosely) on: https://wiki.5e.tools/index.php/5eTools_Install_Guide

cd /usr/local/apache2/htdocs

#### GET LOCAL VERSION ####
if [ -f /usr/local/apache2/htdocs/version ]; then
  LOCAL_VERSION=$(cat /usr/local/apache2/htdocs/version)
else
  LOCAL_VERSION=0
fi

# this variable must be passed into the environment via docker run or docker-compose
# since this variable is required, I declare it explicitly here
# expects "get", "github", or "mega"
# where "get" refers to the old `get.5e.tools` structure,
# "github" refers to the root of a specific github repository,
# and "mega" refers to a mega.nz download link
DL_TYPE=$DL_TYPE

# this variable must be passed into the environment via docker run or docker-compose
# since this variable is required, I declare it explicitly here
# expects a URL with the correct content for the DL_TYPE
DL_LINK=$DL_LINK

# this variable must be passed into the environment via docker run or docker-compose
# since this variable is required, I declare it explicitly here
# expects "true" or "false"
AUTOUPDATE=$AUTOUPDATE 


if [ $AUTOUPDATE = false ]; then 
  # if the user doesn't want to update from a source, 
  # check for local version
  # if local version is found, print version and start server
  # if no local version is found, print error message and exit 1
  echo "Auto update disabled. Checking for local version..."
  if [ -f /usr/local/apache2/htdocs/version ]; then
    LOCAL_VERSION=$(cat /usr/local/apache2/htdocs/version)  
    echo " === Starting (v$LOCAL_VERSION)!"
    httpd-foreground
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
  if [ $SITE_STATUS = 200 ]; then # if the source URL is reachable
    if [ $DL_TYPE = "get" ]; then # the get.5e.tools structure
      echo " === Using get structure to download from $DL_LINK"
      echo " === WARNING: This part of the script has not yet been tested. Please open an issue on the github if you have trouble."
      # get remote version number
      # takes three steps of wizardry. I did not write this, but it works so I don't touch it.
      FILENAME=`curl -s -k -I $DL_LINK/src/|grep filename|cut -d"=" -f2 | awk '{print $1}'` # returns like "5eTools.1.134.0.zip" (with quotes)
      FILENAME=${FILENAME//[$'\t\r\n"']} # remove quotes, returns like 5eTools.1.134.0.zip
      VERSION=`basename ${FILENAME} ".zip"|sed 's/5eTools\.//'` # get version number, returns like 1.134.0
      if [ "$VERSION" != "$LOCAL_VERSION" ]; then
        echo " === Local version ($LOCAL_VERSION) outdated, updating to $VERSION ..."
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
    elif [ $DL_TYPE = "github" ]; then # the github structure
      echo " === Using github structure to update from $DL_LINK"
      echo " === Warning: images will be downloaded automatically, which will take longer"
      if [ -d "./.git" ]; then # if a git repository already exists
        git pull upstream $DL_LINK
      else # if no git repository exists
        git init
        git add .
        git commit -m "Init"
        git remote add upstream $DL_LINK
        git config user.email "autodeploy@jafner.tools"
        git config user.name "AutoDeploy"
      fi
      echo " === Using latest version on $DL_LINK"
      echo " === Starting!"
      httpd-foreground
    elif [ $DL_TYPE = "mega" ]; then # the mega structure
      echo " === Using mega structure to download from $DL_LINK"
      echo " === Warning: This method will overwrite the current local version because it cannot check the remote version"
      echo " === Warning: This method ignores the IMG environment variable."
      # downloading files
      mkdir -p ./download
      megadl --path ./download/ --no-progress --print-names $DL_LINK > filename
      FILENAME=$(cat filename)
      VERSION=$(basename $(cat filename) ".zip"|sed 's/5eTools\.//')
      rm filename
      echo $VERSION > version

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
      echo " === Starting (v$VERSION)!"
      httpd-foreground
    else
      echo " === Could not determine download structure."
      if [ $LOCAL_VERSION != 0 ]; then
        echo " === Falling back to local version: $LOCAL_VERSION"
        echo " === Starting!"
        httpd-foreground
      else
        echo " === No version file found! You must be able to access $DL_LINK to grab the 5eTools files."
        echo " === Hint: Make sure you have the correct DL_TYPE environment variable set."
        exit 1
      fi
    fi
  else # if the download source is not accessible
    echo " === Could not connect to $DL_LINK"
    if [ $LOCAL_VERSION != 0 ]; then
      echo " === Falling back to local version: $LOCAL_VERSION"
      echo " === Starting!"
      httpd-foreground
    else
      echo " === No version file found! You must be able to access $DL_LINK to grab the 5eTools files."
      echo " === Hint: Make sure you have the correct DL_TYPE environment variable set."
      exit 1
    fi
  fi
fi