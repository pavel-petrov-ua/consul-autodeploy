#!/bin/bash

# Firewall requirements
# 8300 - tcp
# 8300  – TCP
# 8301 - TCP & UDP
# 8302 - TCP & UDP
# 8400 - TCP
# 8500 - TCP
# 8600 - TCP & UDP


#install consul
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update -y
sudo apt install consul -y

# create some dir
sudo mkdir -p /etc/consul.d/scripts
sudo mkdir /var/consul

# create config for autoconnect
sudo echo '{
  "server": true,
  "node_name": "consul_s1",
  "datacenter": "dc1",
  "data_dir": "/var/consul/data",
  "bind_addr": "0.0.0.0",
  "client_addr": "0.0.0.0",
  "advertise_addr": "172.31.87.241",
  "bootstrap_expect": 3,
  "retry_join": ["172.31.87.241", "172.31.88.142", "172.31.81.44"],
  "ui": true,
  "log_level": "DEBUG",
  "enable_syslog": true,
  "acl_enforce_version_8": false
}' > /root/config.json

# if this work change _cp_ to _mv_
sudo cp /root/config.json /etc/consul.d/config.json

### hands-deploy
# use "consul keygen" for generate key 
# changes in file  /etc/consul.d/config.json 
# 1. encrypt -- new enrcypt key from colsul keygen
# 2. start_join - new IP address




# auto boot stap

sudo echo "
[Unit]
Description=Consul
Documentation=https://www.consul.io/
#Requires=network-online.target
#After=network-online.target

[Service]
#User=<username>  # Replace <username> with the username of the user running Consul
#Group=<group>    # Replace <group> with the group of the user running Consul
#ExecStart=/usr/local/bin/consul agent -server -ui -data-dir=/tmp/consul -enable-script-checks -config-dir=/etc/consul.d
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d
ExecReload=/usr/bin/consul reload
#ExecStop=/usr/bin/consul leave
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
" > /root/consul.service 

# if this work change _cp_ to _mv_
sudo cp /root/consul.service /etc/systemd/system/consul.service


## create monitoring file

# jenkins
sudo echo '{
  "service": {
    "id": "jenkins",
    "name": "jenkins",
    "address": "172.31.94.92",
    "port": 8080,
    "checks": [
      {
        "id": "http-check",
        "name": "HTTP Check",
        "http": "http://172.31.94.92:8080/",
        "interval": "10s"
      }
    ]
  }
}' > /root/jenkins.json
sudo cp /root/jenkins.json /etc/consul.d/jenkins.json


# nexus
sudo echo '{
  "service": {
    "id": "nexus",
    "name": "nexus",
    "address": "172.31.88.214",
    "port": 8081,
    "checks": [
      {
        "id": "http-check",
        "name": "HTTP Check",
        "http": "http://172.31.88.214:8081/",
        "interval": "10s"
      }
    ]
  }
}' > /root/nexus.json
sudo cp /root/nexus.json /etc/consul.d/nexus.json

#grand acceess 

sudo chown -R consul:consul /etc/consul.d
sudo chown -R consul:consul /var/consul


# after all use auto-start
sudo systemctl daemon-reload
sudo systemctl start consul
sudo systemctl enable consul
sudo systemctl status consul


# restart service
sudo systemctl restart consul

# test
echo 'ok' > ./install.txt
sudo shutdown -r now