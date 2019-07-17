#!/bin/bash
apt-get update && apt-get install -y \
curl \
bc \
parted \
&& curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && usermod -aG docker vagrant && curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && docker-compose --version
#&& rm -rf /var/lib/apt/lists/* ( remove only if you are building docker image to make light weight)
(
echo n
echo
echo 1
echo
echo '+8G'
echo t
echo '8e'
echo p
echo n
echo
echo 2
echo
echo '+8G'
echo t
echo 2
echo '8e'
echo p
echo w
echo q
) | fdisk  /dev/sdb
partprobe
#https://www.tecmint.com/create-lvm-storage-in-linux/
pvcreate /dev/sdb1 /dev/sdb2 && pvs
vgcreate app_docker_vg /dev/sdb1 /dev/sdb2 && vgs
# create 7  GB logical vol . use bc to calculate PEs . one PE=4 MB. Use -L to define size inn GB
lvcreate -l 1792 -n app_data app_docker_vg
lvcreate -l 1792 -n docker_vol app_docker_vg
lvs app_docker_vg
mkfs.ext4 /dev/mapper/app_docker_vg-app_data
sleep 5
mkfs.ext4 /dev/mapper/app_docker_vg-docker_vol
sleep 5
mkdir /app_data /docker_root_vol
mount /dev/mapper/app_docker_vg-app_data /app_data/
mount /dev/mapper/app_docker_vg-docker_vol /docker_root_vol/
df -hT
blkid
#update fstab for persistant mounting
echo "UUID=$(blkid -s UUID -o value /dev/mapper/app_docker_vg-app_data) /app_data ext4 defaults 0 0" | tee -a /etc/fstab
echo "UUID=$(blkid -s UUID -o value /dev/mapper/app_docker_vg-docker_vol) /docker_root_vol ext4 defaults 0 0" | tee -a /etc/fstab
#Moving Docker root dir to new mount 
service docker stop && mv /var/lib/docker /docker_root_vol/ && ln -s /docker_root_vol/docker /var/lib/docker && service docker start
#Setting up Docker registry - https://dzone.com/articles/how-to-setup-docker-private-registry-on-ubuntu-160
echo "192.168.33.89 registry-server" >> /etc/hosts
echo "192.168.33.90 registry-client" >> /etc/hosts
# testing if host name mapping is working
#ping -c 5 registry-client
#generate self signed certificate -  
mkdir /etc/certs
cd /etc/certs
echo "Creating CSR"
openssl req -newkey rsa:4096 -nodes -sha256 -keyout ca.key -x509 -days 365 -out ca.crt \
 -subj "/C=IN/ST=HYD/L=HYD/O=Vagrant/OU=IT/CN=registry-server/emailAddress=www.example.com"

echo "---------------------------"
echo "-----Below is your CERT-----"
echo "---------------------------"
echo
cat ca.cert

echo
echo "---------------------------"
echo "-----Below is your Key-----"
echo "---------------------------"
echo
cat ca.key
# saving cert at /vagrant folder for client to copy
cp /etc/certs/ca.crt /vagrant
cd ~
mkdir auth
docker run  --entrypoint htpasswd  registry -Bbn testuser testpassword > auth/htpasswd

docker run -d -p 5000:5001 --restart=always --name registry -v "$(pwd)"/auth:/auth \
 -v /app_data:/app_data -v /etc/certs:/etc/certs \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd  \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:5001 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/etc/certs/ca.crt \
  -e REGISTRY_HTTP_TLS_KEY=/etc/certs/ca.key \
  -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/app_data registry
  
  #We are changing registry default storage to our addtional lvm volume /app_data
# We are using cutomised port here  

 


