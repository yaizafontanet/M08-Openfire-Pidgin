#!/bin/bash
apt update
apt upgrade -y
apt install -y moreutils
apt install -y net-tools

DOMAIN='insjdayf.hopto.org'
ME=$(echo $HOSTNAME)
IP=$(ifdata -pa eth0)
LAST=$(echo $IP | cut -d . -f 4)
MAC=$(ip addr show $(awk 'NR==3{print $1}' /proc/net/wireless | tr -d :) | awk '/ether/{print $2}')

#Creación de dos usuarios


#instalar postfix y configurar Maildir
apt update
debconf-set-selections <<< "postfix postfix/mailname string insjdayf.hopto.org"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install --assume-yes postfix
cp /etc/postfix/main.cf /etc/postfix/main.cf.backup
postconf -e 'home_mailbox= Maildir/'
systemctl restart postfix.service

#instalar dovecot y configurar
apt update
apt install -y dovecot-core
apt install -y dovecot-pop3d
apt install -y dovecot-imapd
cp /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.backup
sed -i '/^disable_plaintext_auth =.*/s/^/#/g' /etc/dovecot/conf.d/10-auth.conf
echo "disable_plaintext_auth = no" >> /etc/dovecot/conf.d/10-auth.conf
sed -i '/^auth_mechanisms =.*/s/^/#/g' /etc/dovecot/conf.d/10-auth.conf
echo "auth_mechanisms = plain login" >> /etc/dovecot/conf.d/10-auth.conf
cp /etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf.backup
sed -i '/^mail_location =.*/s/^/#/g' /etc/dovecot/conf.d/10-mail.conf
echo "mail_location = mailbox:~/Maildir" >> /etc/dovecot/conf.d/10-mail.conf
apt install -y dovecot-impad
systemctl restart dovecot.service

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

MYSQL_USER='roundcube'
MYSQL_PASSWORD='Yaiza200!'
DB='roundcube'

sudo mysql -h localhost -u root << EOF
create database $DB;
create user $MYSQL_USER@localhost identified by '$MYSQL_PASSWORD';
grant all privileges on $DB.* to $MYSQL_USER@localhost; 
flush privileges;
EOF

#instalar php
apt install -y php7.4 libapache2-mod-php7.4 php7.4-common php7.4-mysql php7.4-cli php-pear php7.4-opcache php7.4-gd php7.4-curl php7.4-cli php7.4-imap php7.4-mbstring php7.4-intl php7.4-soap php7.4-ldap php-imagick php7.4-xml php7.4-zip
pear install Auth_SASL2 Net_SMTP Net_IDNA2-0.1.1 Mail_mime Mail_mimeDecode

#instalar apache
apt-get update
apt-get install -y apache2
systemctl start apache2
systemctl enable apache2

#instalar roundcube
wget https://github.com/roundcube/roundcubemail/releases/download/1.5.2/roundcubemail-1.5.2-complete.tar.gz
tar -xvzf roundcubemail-1.5.2-complete.tar.gz
mv roundcubemail-1.5.2 /var/www/html/roundcube
chown -R www-data:www-data /var/www/html/roundcube/

#configurar arxiu de sites-available per roundcube
RC_ROOT='/var/www/html/roundcube'
RC_SITES='/etc/apache2/sites-available/roundcube.conf'
echo "<VirtualHost *:80>
        DocumentRoot $RC_ROOT
        ServerName webmail.$DOMAIN
        
        <Directory /var/www/html/roundcube/>
            Options -Indexes
            AllowOverride All
            Order allow,deny
            allow from all
        </Directory>

        ErrorLog  ${APACHE_LOG_DIR}/roundcube_error.log
        CustomLog ${APACHE_LOG_DIR}/roundcube_access.log combined
</VirtualHost>" > $RC_SITES
a2ensite $RC_SITES
systemctl restart apache2.service

#Configurar archivo de netplan
cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.backup
rm /etc/netplan/50-cloud-init.yaml
echo "network:
    ethernets:
        eth0:
            dhcp4: true
            dhcp6: false
            match:
                macaddress: $MAC
            set-name: eth0
            nameservers:
                addresses: [$IP]
    version: 2" > /etc/netplan/50-cloud-init.yaml
netplan apply

#instalar y configurar bind9
apt update
apt install -y bind9
cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup
rm /etc/bind/named.conf.options
echo "options {
    directory "/var/cache/bind";
    forwarders {
        80.58.61.250;
        80.58.61.254;
    };
    dnssec-validation auto;
    listen-on-v6 { any; };
};" > /etc/bind/named.conf.options

cp /etc/bind/named.conf.local /etc/bind/named.conf.local.backup
rm /etc/bind/named.conf.local
echo "zone "$DOMAIN" {
    type master;
    file "/etc/bind/forward.$DOMAIN";
    };
    zone "1.0.10.in-addr.arpa" {
        type master;
        file "/etc/bind/reverse.$DOMAIN";
};" > /etc/bind/named.conf.local

echo ""$TTL"    604800
@               IN      SOA     $ME.$DOMAIN. root.$DOMAIN. (
                            2         ; Serial
                       604800         ; Refresh
                        86400         ; Retry
                      2419200         ; Expire
                       604800 )       ; Negative Cache TTL
;
@               IN      NS      $ME.$DOMAIN.
@               IN      A       $IP
@               IN      AAAA    ::1
$ME   IN      A       $IP
    
webmail         IN      CNAME   $ME
" > /etc/bind/forward.$DOMAIN 

echo ""$TTL"    604800
@     IN      SOA     $ME.$DOMAIN. root.$DOMAIN. (
                            1         ; Serial
                       604800         ; Refresh
                        86400         ; Retry
                      2419200         ; Expire
                       604800 )       ; Negative Cache TTL
;
@     IN      NS      $ME.
$LAST   IN      PTR     $ME.$DOMAIN.
" > /etc/bind/reverse.$DOMAIN 
sudo systemctl restart bind9.service