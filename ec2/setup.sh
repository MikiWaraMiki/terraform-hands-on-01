#!/bin/bash
# For User Data
# 1. Locale and User Date Settings
# 2. yum update
# 3. httpd and httpd-devel and mysql-client install

# Locale Set
localctl set-locale LANG=ja-JP.UTF-8
source /etc/locale.conf

# Set Timezone
timedatectl set-timezone Asia/Tokyo

# yum pid 
rm -rf /var/run/yum.pid

# yum update
yum update -y

# Apache install
yum install -y httpd24 httpd24-devel
echo "<h1> Hello </h1>" >> /var/www/html/index.html
# Install Mysql
yum install mysql


# Start Apache
systemctl enable httpd
systemctl start httpd