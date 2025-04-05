#!/usr/bin/env bash

sudo apt update && sudo apt upgrade
sudo apt autoremove

DBDIR="/data/db"

# install build essentials
sudo apt install -y build-essential wget gnupg

echo "
----------------------
  NODE & NPM
----------------------
"
# add nodejs LTS ppa (personal package archive) from nodesource
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
# install nodejs and npm
sudo apt install -y nodejs

echo "
----------------------
  MONGODB
----------------------
"
# import mongodb 7.0 public gpg key
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor
apt-key list
# create the /etc/apt/sources.list.d/mongodb-org-7.0.list file for mongodb
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
# reload local package database
sudo apt update
# install the latest version of mongodb
sudo apt install -y mongodb-org
# start mongodb
sudo systemctl start mongod
# set mongodb to start automatically on system startup
sudo systemctl enable mongod

# check /data/db directory present if not create
if [ ! -d "$DBDIR" ];then
	sudo mkdir -p /data/db
fi
#chagne permission
sudo chmod -R 755 /data/

echo "
-----------------------------------
    installing pisignage-server
-----------------------------------
"
sudo git clone https://github.com/colloqi/pisignage-server
cd pisignage-server
npm install

#create media and thumbnail directory
cd ..
mkdir media
sudo chmod 755 -R ./media

echo "
----------------------
  NGINX
----------------------
"
# install nginx
sudo apt install -y nginx

echo "
----------------------
  UFW (FIREWALL)
----------------------
"
# allow ssh connections through firewall
sudo ufw allow OpenSSH
# allow http & https through firewall
sudo ufw allow 'Nginx Full'
# enable firewall
sudo ufw --force enable
