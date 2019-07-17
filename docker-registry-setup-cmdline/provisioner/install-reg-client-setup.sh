#!/bin/bash
apt-get update && apt-get install -y \
curl \
&& curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && usermod -aG docker vagrant && curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && docker-compose --version
#Setting up Docker registry - https://dzone.com/articles/how-to-setup-docker-private-registry-on-ubuntu-160
echo "192.168.33.89 registry-server" >> /etc/hosts
echo "192.168.33.90 registry-client" >> /etc/hosts
#ping -c 5 registry-server
# Based on the port mapping we have to create this dir and copy the crt. So make sure to note the port number e,g -p 5000:5001 
mkdir -p /etc/docker/certs.d/registry-server:5000
cp -f /vagrant/ca.crt /etc/docker/certs.d/registry-server:5000/ && rm -f /vagrant/ca.crt
#Testing registry - 
curl -u testuser:testpassword -k -X GET https://registry-server:5000/v2/_catalog




