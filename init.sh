#!/bin/bash
# based on: https://wiki.5e.tools/index.php/5eTools_Install_Guide

echo "STARTING" > /status
curl -s get.5e.tools > /dev/null

if [ $? = 0 ] # if the get.5e.tools site is accessible
then
  echo "CHECKING FOR UPDATE" > /status
  FN=`curl -s -k -I https://get.5e.tools/src/|grep filename|cut -d"=" -f2 | awk '{print $1}'` # get filename of most recent version
  FN=${FN//[$'\t\r\n"']} # remove quotes
  echo "FN: $FN"
  FN_IMG=`curl -s -k -I https://get.5e.tools/img/|grep filename|cut -d"=" -f2 | awk '{print $1}'` # get filename of most recent image pack
  FN_IMG=${FN_IMG//[$'\t\r\n"']} # remove quotes
  echo "FN_IMG: $FN_IMG" 
  VER=`basename ${FN} ".zip"|sed 's/5eTools\.//'` # get version number
  echo "VER: $VER"
  CUR=$(<version)

  echo " === Remote version: $VER"
  echo " === Local version: $CUR"

  if [ "$VER" != "$CUR" ]
  then
    echo " === Local version outdated, updating..."
    echo -n $VER > version
    echo "DOWNLOADING" > /status

    rm ./index.html 2> /dev/null || true

    echo " === Downloading new remote version..."
    cd ./download/
    curl --progress-bar -k -O -J https://get.5e.tools/src/ -C -
    
    if [ "$IMG" = "true" ]; then
      echo " === Downloading images === "
      echo "DOWNLOADING IMAGES" > /status
      curl --progress-bar -k -O -J https://get.5e.tools/img/ -C -
    fi
    cd ..

    echo " === Extracting site..."
    echo "EXTRACTING" > /status
    7z x ./download/$FN -o./ -y

    if [ "$IMG" = "true" ]; then
      echo " === Extracting images..."
      echo "EXTRACTING IMAGES" > /status
      7z x ./download/$FN_IMG -o./img -y
      mv ./img/tmp/5et/img/* ./img
      rm -r ./img/tmp
    fi

    echo " === Configuring..."
    echo "CONFIGURING" > /status
    find . -name \*.html -exec sed -i 's/"width=device-width, initial-scale=1"/"width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no"/' {} \;
    sed -i 's/<head>/<head>\n<link rel="apple-touch-icon" href="icon\/icon-512.png">/' index.html
    sed -i 's/navigator.serviceWorker.register("\/sw.js/navigator.serviceWorker.register("sw.js/' index.html
    sed -i 's/navigator.serviceWorker.register("\/sw.js/navigator.serviceWorker.register("sw.js/' 5etools.html

    echo " === Cleaning up downloads"
    echo "CLEANING" > /status
    find ./download/ -type f ! -name "*.${VER}.zip" -exec rm {} +

    echo " === Done!"
    echo "INIT" > /status
  else
    echo " === Local version matches remote, no action."
    echo "INIT" > /status
  fi
else # if get.5e.tools is not accessible
  echo " === No internet access! Checking for existing files"
  if [ -f /usr/local/apache2/htdocs/version ]
  then
    echo " === Version file found: $(cat /usr/local/apache2/htdocs/version)"
    echo " === Starting!"
  else
    echo " === No version file found! You need to be online to grab the 5eTools files"
    exit 1
  fi
fi

httpd-foreground
