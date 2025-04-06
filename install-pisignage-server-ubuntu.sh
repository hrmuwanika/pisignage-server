#!/bin/bash

sudo apt update && sudo apt upgrade
sudo apt autoremove

DBDIR="/data/db"

# install build essentials
sudo apt install -y build-essential wget gnupg nano curl git imagemagick ffmpeg

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
# import mongodb 8.0 public gpg key
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor

# create the /etc/apt/sources.list.d/mongodb-org-8.0.list file for mongodb
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list

# reload local package database
sudo apt update
# install the latest version of mongodb
sudo apt install -y mongodb-org
# start mongodb
sudo systemctl start mongod
# set mongodb to start automatically on system startup
sudo systemctl enable mongod

cd /

# check /data/db directory present if not create
if [ ! -d "$DBDIR" ];then
	sudo mkdir -p /data/db
fi
#change permission
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
mkdir media/_thumbnails
sudo chmod 755 -R ./media

echo "
----------------------
  UFW (FIREWALL)
----------------------
"
# allow ssh connections through firewall
sudo apt install -y ufw
sudo ufw allow 22/tcp
sudo ufw allow 3000/tcp
sudo ufw --force enable

sudo cat <<EOF > /etc/systemd/system/pisignage.service

[Unit]
Description=pisignage Player -  Server Software
#Include the After directive to make sure mongodb is running
After=mogodb.service

[Service]
# Key `User` specifies that the server will run under the pisignage user 
# Hash User & Group out if you want root to run it
#User=pisignage
#Group=pisignage 
Restart=always
RestartSec=10
WorkingDirectory=/root/pisignage-server
ExecStart=/usr/bin/node /root/pisignage-server/server.js >> /var/log/pisignage.log 2>&1
#StandardOutput=
#StandardError=/var/log/pisignageserver.log
Environment=NODE_ENV=development PORT=3000

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable pisignage.service
sudo systemctl start pisignage.service

echo " Pisignage server installation is completed"
# sudo journalctl -u pisignage.service -n 200 


