sudo apt-get install curl build-essential gdebi gdebi-core libpq-dev -y

source ruby_install.sh

source nodeinstall.sh

cd ~/gamerist

source update_dev_redis.sh

cd ~/gamerist

curl -O https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.1/rabbitmq-server_3.6.1-1_all.deb

sudo gdebi rabbitmq-server_3.6.1-1_all.deb

rm rabbitmq-server_*.deb

cd www

bundle config --global jobs 8

bundle

source update_mozilla.sh

echo ""

echo "GAMERIST development setup complete"
echo "You must now manually install and set up:"

echo " * handlr environment with steam servers"
