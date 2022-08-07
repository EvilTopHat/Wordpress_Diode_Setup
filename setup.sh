echo "script must be run as root"
#setup firewall to block all but ssh
ufw allow ssh
#update software
apt-get update && apt-get upgrade -y
#setup automatic updates TODO test
#apt-get install unattended-upgrades
#systemctl enable unattended-upgrades #should already be enabled but this line is just for double chekcing

#install apache

#install mysql

#install wordpress

#install diode and publish new site
#curl -Ssf https://diode.io/install.sh | sh
#diode publish -public 80:80 