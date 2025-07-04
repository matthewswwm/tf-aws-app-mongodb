#!/bin/bash
#
### mongodb_install.sh
# This shellscript is responsible for installing MongoDB. It also configures MongoDB to listen for all connections.
# Default config file location: /etc/mongod.conf
# Tested on an amazon linux 2 machine

set -e
set -x

echo "[INFO]: Starting MongoDB installation procedure"

# Sets up yum package for MongoDB & install
echo -e "[mongodb-org-7.0]\nname=MongoDB Repository\nbaseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/7.0/x86_64/\ngpgcheck=1\nenabled=1\ngpgkey=https://pgp.mongodb.com/server-7.0.asc" | sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo
sudo yum install -y mongodb-org

# Command to add bindIp value to the config file.
sudo grep -q 'bindIp:' /etc/mongod.conf \
     && sudo sed -i 's/^\([[:space:]]*bindIp:\).*/\1 0.0.0.0/' /etc/mongod.conf \
     || sudo sed -i '/^net:/a \  bindIp: 0.0.0.0' /etc/mongod.conf

# Start mongod to ensure it's running before user creation
sudo systemctl start mongod
sleep 10
sudo systemctl status mongod

# [TODO] Create admin user

# [TODO] Create tasky user

# Updating of file permissions to mongod (unnecessary)
# sudo chown -R mongod:mongod /var/lib/mongo
# sudo chown -R mongod:mongod /var/log/mongodb
# sudo chown mongod:mongod /etc/mongod.conf

echo "[INFO]: MongoDB Installation completed"
