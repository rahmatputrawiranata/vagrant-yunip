sudo apt-get -y update
sudo apt-get -y install nginx
sudo apt-get -y install debconf-utils
# ufw allow 'Nginx HTTP'
# ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'
systemctl start nginx
systemctl enable nginx
sudo apt-get -y install software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt-get -y update
sudo apt-get -y  --allow-unauthenticated install wget php7.2-fpm php7.2-common php7.2-mbstring php7.2-xmlrpc php7.2-soap php7.2-gd php7.2-xml php7.2-cli php7.2-curl php7.2-zip
cp /var/www/default /etc/nginx/sites-available/default

systemctl restart nginx
echo -e "\n--- COMPOSER ---\n"
sudo curl -sS https://getcomposer.org/installer | php > /dev/null
sudo mv composer.phar /usr/local/bin/composer
composer global require "squizlabs/php_codesniffer=*"
sudo ln -s /home/vagrant/.config/composer/vendor/bin/phpcs /usr/local/bin/phpcs

echo -e "\n--- FRONTEND TOOLS ---\n"
sudo apt-get install -y npm
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs

DBUSER=root
DBPASSWD=root

echo "--- MYSQL ---"
sudo apt-get install -y debconf-utils -y > /dev/null
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $DBPASSWD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DBPASSWD"
sudo apt-get install -y mysql-server mysql-client
sudo sed -i 's/bind-address/bind-address = 0.0.0.0#/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo mysql -u root -proot -e "GRANT ALL PRIVILEGES ON *.* TO '$DBUSER'@'%' IDENTIFIED BY '$DBUSER' WITH GRANT OPTION; FLUSH PRIVILEGES;"
sudo echo 'character-set-server=utf8mb4' >> /etc/mysql/mysql.conf.d/mysqld.cnf
sudo echo 'collation-server=utf8mb4_unicode_ci' >> /etc/mysql/mysql.conf.d/mysqld.cnf
sudo mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -p$DBPASSWD -u $DBUSER mysql
sudo service mysql restart

apt update

# "ubuntu/curl/install-curl.sh"
apt install -y curl
# "ubuntu/curl/install-curl.sh"

apt install -y build-essential

rm /tmp/redis-stable.tar.gz
rm -fr /tmp/redis-stable
curl http://download.redis.io/redis-stable.tar.gz -o /tmp/redis-stable.tar.gz
tar xvzf /tmp/redis-stable.tar.gz -C /tmp
make -C /tmp/redis-stable
make install -C /tmp/redis-stable

adduser --system --group --no-create-home redis

mkdir -p /etc/redis
mkdir -p /var/lib/redis
chown redis:redis /var/lib/redis
chmod 770 /var/lib/redis

cp /tmp/redis-stable/redis.conf /etc/redis/redis.conf
sed -i "s/^supervised no/supervised systemd/g" /etc/redis/redis.conf
sed -i "s/^dir \.\//dir \/var\/lib\/redis/g" /etc/redis/redis.conf

cat <<EOF | tee /lib/systemd/system/redis.service > /dev/null
[Unit]
Description=Redis In-Memory Data Store
After=network.target
[Service]
User=redis
Group=redis
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=always
[Install]
WantedBy=multi-user.target
EOF

rm /tmp/redis-stable.tar.gz
rm -fr /tmp/redis-stable

