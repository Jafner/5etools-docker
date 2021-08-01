#!/bin/bash
# based on: https://wiki.5e.tools/index.php/5eTools_Install_Guide
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

  rm ./index.html 2> /dev/null || true

  echo " === Downloading new remote version..."
  cd ./download/
  curl --progress-bar -k -O -J https://get.5e.tools/src/ -C -
  
  if [ "$IMG" = "true" ]; then
    curl --progress-bar -k -O -J https://get.5e.tools/img/ -C -
  fi
  cd ..

  echo " === Extracting site..."
  7z x ./download/$FN -o./ -y

  if [ "$IMG" = "true" ]; then
    echo " === Extracting images..."
    7z x ./download/$FN_IMG -o./img -y
    mv ./img/tmp/5et/img/* ./img
    rm -r ./img/tmp
  fi

  echo " === Configuring..."
  find . -name \*.html -exec sed -i 's/"width=device-width, initial-scale=1"/"width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no"/' {} \;
  sed -i 's/<head>/<head>\n<link rel="apple-touch-icon" href="icon\/icon-512.png">/' index.html
  sed -i 's/navigator.serviceWorker.register("\/sw.js/navigator.serviceWorker.register("sw.js/' index.html
  sed -i 's/navigator.serviceWorker.register("\/sw.js/navigator.serviceWorker.register("sw.js/' 5etools.html

  echo " === Cleaning up downloads"
  find ./download/ -type f ! -name "*.${VER}.zip" -exec rm {} +

  echo " === Done!"
else
  echo " === Local version matches remote, no action."
fi

httpd-foreground
