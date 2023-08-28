#!/bin/bash
# based (loosely) on: https://wiki.5e.tools/index.php/5eTools_Install_Guide

# Ensure clean, non-root ownership of the htdocs directory.
# Delete index.html if it's the stock apache file. Otherwise it impedes the git clone.
chown -R $PUID:$PGID /usr/local/apache2/htdocs
if grep -Fq '<html><body><h1>It works!</h1></body></html>' "/usr/local/apache2/htdocs/index.html"; then
  rm /usr/local/apache2/htdocs/index.html
fi

# If the user doesn't want to update from a source, 
# check for local version.
# If local version is found, print version and start server.
# If no local version is found, print error message and exit.
if [ "$OFFLINE_MODE" = "TRUE" ]; then 
  echo " === Offline mode is enabled. Will try to launch from local files. Checking for local version..."
  if [ -f /usr/local/apache2/htdocs/package.json ]; then
    VERSION=$(jq -r .version package.json) # Get version from package.json
    echo " === Starting version $VERSION"
    httpd-foreground
  else
    echo " === No local version detected. Exiting."
    exit 1
  fi
fi

# The SOURCE variable must be set if OFFLINE_MODE is not TRUE
if [ -z "${SOURCE}" ]; then
  echo " === SOURCE variable not set. Expects one of \"GITHUB\", \"GET5ETOOLS\", or \"GET5ETOOLS-NOIMG\". Exiting."
  exit 1
fi

# Move to the working directory for working with files.
cd /usr/local/apache2/htdocs

echo " === Checking directory permissions for /usr/local/apache2/htdocs"
ls -ld /usr/local/apache2/htdocs

SOURCE=${SOURCE}
echo "SOURCE=$SOURCE"
case $SOURCE in 
  GITHUB | GITHUB-NOIMG) # Source is the github mirror
    DL_LINK=https://github.com/5etools-mirror-1/5etools-mirror-1.github.io.git
    echo " === Using GitHub mirror at $DL_LINK"
      if [ ! -d "./.git" ]; then # if no git repository already exists
        echo " === No existing git repository, creating one"
        git config --global user.email "autodeploy@jafner.tools"
        git config --global user.name "AutoDeploy"
        git config --global pull.rebase false # Squelch nag message
        git config --global --add safe.directory '*' # Disable directory ownership checking, required for mounted volumes
        git clone --filter=blob:none --no-checkout $DL_LINK . # clone the repo with no files and no object history
        git config core.sparseCheckout true # enable sparse checkout
        git sparse-checkout init 
      else
        echo " === Using existing git repository"
      fi
      if [[ "$SOURCE" == *"NOIMG"* ]]; then # if user does not want images
        echo -e '/*\n!img' > .git/info/sparse-checkout # sparse checkout should include everything except the img directory
        echo " === Pulling from GitHub without images..."
      else
        echo -e '/*' > .git/info/sparse-checkout # sparse checkout should include everything
        echo " === Pulling from GitHub with images... (This will take a while)"
      fi
      git checkout
      git fetch
      git pull
      VERSION=$(jq -r .version package.json) # Get version from package.json
      if [[ `git status --porcelain` ]]; then
        git restore .
      fi

      echo " === Starting version $VERSION"
      httpd-foreground
      ;;

  GET5ETOOLS | GET5ETOOLS-NOIMG)
    DL_LINK=https://get.5e.tools
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
        
        if [ "$SOURCE" != *"NOIMG"* ]; then # download images
          echo " === Downloading images... "
          curl --progress-bar -k -O -J $DL_LINK/img/ -C -
        fi
        
        cd ..

        echo " === Extracting site..."
        7z x ./download/$FILENAME -o./ -y

        if [ "$SOURCE" != *"NOIMG"* ]; then # extract images
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
      ;;

  
  *)
    echo "SOURCE variable set incorrectly. Exiting..."
    exit
    ;;

esac
