#!/bin/bash
apt update
apt upgrade -y
apt install -y moreutils
apt install -y net-tools

DOMAIN='jdayf.cf'
ME=$(echo $HOSTNAME)
IP=$(ifdata -pa eth0)
LAST=$(echo $IP | cut -d . -f 4)
MAC=$(ip addr show $(awk 'NR==3{print $1}' /proc/net/wireless | tr -d :) | awk '/ether/{print $2}')

#instalar java JDK
apt install -y default-jdk

#instalar openfire
wget https://www.igniterealtime.org/downloadServlet?filename=openfire/openfire_4.6.2_all.deb -O openfire4.6.2.deb
apt install -y ./openfire2.6.2.deb
systemctl enable --now openfire
systemctl restart openfire
apt install -y software-properties-common
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8

#instalar mysql-server i configurar
sudo apt update
sudo apt install -y mysql-server

#sudo mysql_sercure_installation
MYSQL_ROOT_PASSWORD='Yaiza200!'
MYSQL=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $11}') 
SECURE_MYSQL=$(expect -c " 

set timeout 10 
spawn mysql_secure_installation 

expect \"Enter password for user root:\" 
send \"$MYSQL\r\" 
expect \"New password:\" 
send \"$MYSQL_ROOT_PASSWORD\r\" 
expect \"Re-enter new password:\" 
send \"$MYSQL_ROOT_PASSWORD\r\" 
expect \"Change the password for root ?\ ((Press y\|Y for Yes, any other key for No) :\" 
send \"n\r\" 
expect \"Do you wish to continue with the password provided?\(Press y\|Y for Yes, any other key for No) :\" 
send \"y\r\" 
expect \"Remove anonymous users?\(Press y\|Y for Yes, any other key for No) :\" 
send \"y\r\" 
expect \"Disallow root login remotely?\(Press y\|Y for Yes, any other key for No) :\" 
send \"n\r\" 
expect \"Remove test database and access to it?\(Press y\|Y for Yes, any other key for No) :\" 
send \"y\r\" 
expect \"Reload privilege tables now?\(Press y\|Y for Yes, any other key for No) :\" 
send \"y\r\" 
expect eof 
")
echo $SECURE_MYSQL

MYSQL_USER='admopenfire'
MYSQL_PASSWORD='Yaiza200!'
DB='openfire'

sudo mysql -h localhost -u root << EOF
create database $DB;
grant all privileges on $DB.* to $MYSQL_USER@localhost identified by '$MYSQL_PASSWORD'; 
flush privileges;
EOF

#importar base de datos openfire
mysql $DB < /usr/share/openfire/resources/database/openfire_mysql.sql

#Configurar firewall
ufw enable
ufw default deny
ufw allow ssh
for i in 9090 9091 5222 7777 7070 7443; do sudo ufw allow $i; done
