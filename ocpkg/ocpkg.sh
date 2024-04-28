#!/bin/bash
#I don't usually do that much shell scripting, so this is mostly new to me.
#If you think this is poorly coded, that's why.

set -e

export OP="$1"

if ! [ "$#" = "2" ]; then
 echo "Usage: ocpkg <install|remove> <package>"
 exit 0
fi

export PACKAGE="$2"

mkdir -p /tmp/ocpkg/

if [ "$OP" = "install" ]; then
 wget -c -O /tmp/ocpkg/"$PACKAGE".tar https://github.com/Ocawesome101/ocpackages/raw/master/"$PACKAGE".tar
 cd /tmp/ocpkg/ 
 tar xf /tmp/ocpkg/"$PACKAGE".tar
 cd /tmp/ocpkg/"$PACKAGE"
 chmod +x install.sh uninstall.sh
 ./install.sh
 mkdir -p /etc/ocpkg/"$PACKAGE"/
 cp uninstall.sh /etc/ocpkg/"$PACKAGE"/
 chmod a+x /usr/bin/"$PACKAGE" && echo "Package $PACKAGE has been installed!"
else
 if [ "$OP" = "remove" ]; then
  cd /etc/ocpkg/"$PACKAGE"/
  ./uninstall.sh
  cd ..
  rm "$PACKAGE"
  echo "Package $PACKAGE has hopefully been removed"
 fi
fi
