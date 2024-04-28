#!/bin/bash
# ONLY for Ubuntu/Debian
echo "Installing Git, cmdtest, and NPM..."
sudo apt-get install git npm cmdtest
cd "$HOME"
echo "Downloading files..."
git clone https://github.com/iAmWillShepherd/desktop.git
cd "$HOME"/desktop
echo "Installing dependencies..."
npm install
echo "Creating start script at $HOME/Desktop/gitdesktop.sh"
mkdir -p "$HOME"/Desktop
cd "$HOME"/Desktop
echo "cd $HOME/desktop" > gitdesktop.sh
echo "npm start" > gitdesktop.sh
chmod +x gitdesktop.sh
