#!/bin/bash

echo "script must be run as root"
echo "if prompted press accept the qustions in the prompts to continue"
#genearte passwords
wordpress_user_admin="`openssl rand -hex 10`"
mysql_pass="`openssl rand -hex 64`"
mysql_user_pass="`openssl rand -hex 64`"
cd ~/
echo "installation and software passwords" > passwords.txt
echo "wordpress_admin_password=$wordpress_user_admin" >> passwords.txt 
echo "mysql_root=$mysql_pass" >> passwords.txt 
echo "mysql_wordpress=$mysql_user_pass" >> passwords.txt 
#setup firewall to block all but ssh
ufw allow ssh
ufw --force enable 
#update software
apt-get update && apt-get upgrade -y
#setup automatic updates TODO test
#apt-get install unattended-upgrades
#systemctl enable unattended-upgrades #should already be enabled but this line is just for double chekcing

#install packages
#https://ubuntu.com/tutorials/install-and-configure-wordpress#2-install-dependencies
apt-get install apache2 \
                 unzip \
                 ghostscript \
                 libapache2-mod-php \
                 mariadb-server \
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
systemctl reload apache2
systemctl restart apache2

#start mysql and run secure script
systemctl start mariadb.service
mysql_secure_installation <<EOF
y
$mysql_pass
$mysql_pass
y
y
y
y
y
EOF

mysql --user="root" --password="$mysql_pass" --execute="CREATE DATABASE wordpress;"
mysql --user="root" --password="$mysql_pass" --execute="CREATE USER wordpress@localhost IDENTIFIED BY '$mysql_user_pass';"
mysql --user="root" --password="$mysql_pass" --execute="GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER ON wordpress.* TO wordpress@localhost;"
mysql --user="root" --password="$mysql_pass" --execute="FLUSH PRIVILEGES;"
#configure wordpress config
sudo -u www-data cp /srv/www/wordpress/wp-config-sample.php /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/database_name_here/wordpress/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/username_here/wordpress/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i -e "s/password_here/${mysql_user_pass}/g" /srv/www/wordpress/wp-config.php

wget -O /tmp/wp.keys https://api.wordpress.org/secret-key/1.1/salt/
sed -i "s/.*AUTH_KEY.*//" /srv/www/wordpress/wp-config.php
sed -i "s/.*SECURE_AUTH_KEY.*//" /srv/www/wordpress/wp-config.php
sed -i "s/.*LOGGED_IN_KEY.*//" /srv/www/wordpress/wp-config.php
sed -i "s/.*NONCE_KEY.*//" /srv/www/wordpress/wp-config.php
sed -i "s/.*AUTH_SALT.*//" /srv/www/wordpress/wp-config.php
sed -i "s/.*SECURE_AUTH_SALT.*//" /srv/www/wordpress/wp-config.php
sed -i "s/.*LOGGED_IN_SALT.*//" /srv/www/wordpress/wp-config.php
sed -i "s/.*NONCE_SALT.*/begin_insert_here/" /srv/www/wordpress/wp-config.php
sed -i '/begin_insert_here/r /tmp/wp.keys' /srv/www/wordpress/wp-config.php
sed -i "s/begin_insert_here//" /srv/www/wordpress/wp-config.php
rm /tmp/wp.keys

#install diode and publish new site
curl -Ssf https://diode.io/install.sh | sh
export PATH=/root/opt/diode:$PATH
diode_address=`diode config 2>&1 | awk '/<address>/ { print $(NF) }'`

#install wordpress cli
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/bin/wp
chmod +x /usr/bin/wp

#finish installation
wp core install --allow-root --path="/srv/www/wordpress" --title="wordpress diode" --url="${diode_address}.diode.link" --admin_email="admin@localhost.com"  --admin_password="$wordpress_user_admin" --admin_user="admin"

#install plugins
wp plugin install wp-fail2ban --allow-root --path="/srv/www/wordpress"
wp plugin activate wp-fail2ban --allow-root --path="/srv/www/wordpress"
wp theme install --allow-root --path="/srv/www/wordpress" https://github.com/DiscipleTools/disciple-tools-theme/releases/latest/download/disciple-tools-theme.zip
wp theme activate --allow-root --path="/srv/www/wordpress" disciple-tools-theme
chown -Rf www-data.www-data /srv/www
#cp /etc/skel/.bashrc /root

#start diode server
echo "${diode_address}.diode.link"
diode publish -public 80:80 &

#display login instructions
echo "wordpress url is http://${diode_address}.diode.link"
echo "log into wordpress with the user name admin"
echo "and the password $wordpress_user_admin"
echo "remember to change the password and save it in a password manager"
