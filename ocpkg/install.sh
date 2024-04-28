#!/bin/bash
#Install script for OCPKG
#Must be run as root!
echo "This script must be run as root."
chmod a+x *
cp ocpkg.sh /usr/bin/
cp update-ocpkg /usr/bin/
mv /usr/bin/ocpkg.sh /usr/bin/ocpkg
mkdir -p /etc/ocpkg
echo "WARNING: THIS PROJECT IS STILL IN DEVELOPMENT. It should, however, be in a usable state."
