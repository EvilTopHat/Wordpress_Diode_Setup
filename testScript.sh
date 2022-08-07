#!/bin/bash

# https://gist.github.com/dongilbert/951776
# Install script for Latest WordPress by Johnathan Williamson - extended by Don Gilbert
# Disclaimer: It might not bloody work
# Disclaimer 2: I'm not responsible for any screwups ... :)

# DB Variables
echo "MySQL Host:"
read mysqlhost
export mysqlhost

echo "MySQL DB Name:"
read mysqldb
export mysqldb

echo "MySQL DB User:"
read mysqluser
export mysqluser

echo "MySQL Password:"
read mysqlpass
export mysqlpass

# WP Variables
echo "Site Title:"
read wptitle
export wptitle

echo "Admin Username:"
read wpuser
export wpuser

echo "Admin Password:"
read wppass
export wppass

echo "Admin Email"
read wpemail
export wpemail

# Site Variables
echo "Site URL (ie, www.youraddress.com):"
read siteurl
export siteurl

# Download latest WordPress and uncompress
wget http://wordpress.org/latest.tar.gz
tar zxf latest.tar.gz
mv wordpress/* ./

# Grab our Salt Keys
wget -O /tmp/wp.keys https://api.wordpress.org/secret-key/1.1/salt/

# Butcher our wp-config.php file
sed -e "s/localhost/"$mysqlhost"/" -e "s/database_name_here/"$mysqldb"/" -e "s/username_here/"$mysqluser"/" -e "s/password_here/"$mysqlpass"/" wp-config-sample.php > wp-config.php
sed -i '/#@-/r /tmp/wp.keys' wp-config.php
sed -i "/#@+/,/#@-/d" wp-config.php

# Run our install ...
curl -d "weblog_title=$wptitle&user_name=$wpuser&admin_password=$wppass&admin_password2=$wppass&admin_email=$wpemail" http://$siteurl/wp-admin/install.php?step=2

# Tidy up
rmdir wordpress
rm latest.tar.gz
rm /tmp/wp.keys