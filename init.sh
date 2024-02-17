#!/bin/bash

# Print current user ID
id

# Ensure clean, non-root ownership of the htdocs directory.
chown -R $PUID:$PGID /usr/local/apache2/htdocs

# Delete index.html if it's the stock apache file. Otherwise it impedes the git clone.
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

# Move to the working directory for working with files.
cd /usr/local/apache2/htdocs

echo " === Checking directory permissions for /usr/local/apache2/htdocs"
ls -ld /usr/local/apache2/htdocs

DL_LINK=${DL_LINK:-https://github.com/5etools-mirror-2/5etools-mirror-2.github.io.git}
IMG_LINK=${IMG_LINK:-https://github.com/5etools-mirror-2/5etools-img}

echo " === Using GitHub mirror at $DL_LINK"
if [ ! -d "./.git" ]; then # if no git repository already exists
    echo " === No existing git repository, creating one"
    git config --global user.email "autodeploy@localhost"
    git config --global user.name "AutoDeploy"
    git config --global pull.rebase false # Squelch nag message
    git config --global --add safe.directory '/usr/local/apache2/htdocs' # Disable directory ownership checking, required for mounted volumes
    git clone $DL_LINK . # clone the repo with no files and no object history
else
    echo " === Using existing git repository"
    git config --global --add safe.directory '/usr/local/apache2/htdocs' # Disable directory ownership checking, required for mounted volumes
fi

if ! [[ "$IMG" == "TRUE" ]]; then # if user wants images
    echo " === Pulling images from GitHub... (This will take a while)"
    git submodule add -f $IMG_LINK /usr/local/apache2/htdocs/img
fi

echo " === Pulling latest files from GitHub..."
git checkout
git fetch
git pull --depth=1
VERSION=$(jq -r .version package.json) # Get version from package.json

if [[ `git status --porcelain` ]]; then
    git restore .
fi

echo " === Starting version $VERSION"

httpd-foreground