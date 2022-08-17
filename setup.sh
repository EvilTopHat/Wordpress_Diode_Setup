echo "script must be run as root"
echo "if prompted press accept the qustions in the prompts to continue"
#setup firewall to block all but ssh
ufw allow ssh
ufw --force enable 
#update software
apt-get update && apt-get upgrade -y
#setup automatic updates TODO test
#apt-get install unattended-upgrades
#systemctl enable unattended-upgrades #should already be enabled but this line is just for double chekcing

#install apache
#https://ubuntu.com/tutorials/install-and-configure-wordpress#2-install-dependencies
apt-get install apache2 \
                 ghostscript \
                 libapache2-mod-php \
                 mysql-server \
                 php \
                 php-bcmath \
                 php-curl \
                 php-imagick \
                 php-intl \
                 php-json \
                 php-mbstring \
                 php-mysql \
                 php-xml \
                 php-zip -y
#install wordpress
mkdir -p /srv/www
chown www-data: /srv/www
curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www
#Configure Apache for WordPress
echo "<VirtualHost *:80>
    DocumentRoot /srv/www/wordpress
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory /srv/www/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>" > /etc/apache2/sites-available/wordpress.conf
#Enable the site
a2ensite wordpress
a2enmod rewrite
a2dissite 000-default
service apache2 reload
#install diode and publish new site
#curl -Ssf https://diode.io/install.sh | sh
#diode publish -public 80:80 
