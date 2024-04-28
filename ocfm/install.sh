#!/bin/bash
#This script will install OCFM, and all its dependencies, for all users.
#Requires root privileges!
echo "Press ctrl-C now to cancel."
sleep 1
sudo chmod a+x OCFM2.py 
sudo cp OCFM2.py /usr/bin
sudo mv /usr/bin/OCFM2.py /usr/bin/ocfm
sudo echo "[Desktop Entry]" >> ocfm.desktop
sudo echo "Type=Application" >> ocfm.desktop
sudo echo "Name=OC File Manager" >> ocfm.desktop
sudo echo "Exec=xterm -e /usr/bin/ocfm" >> ocfm.desktop
sudo echo "Icon=file-manager" >> ocfm.desktop
sudo echo "Categories=System,Accessories" >> ocfm.desktop
sudo mv ocfm.desktop /usr/share/applications
echo Script has finished
