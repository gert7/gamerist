sudo apt-get install curl postgresql build-essential gdebi -y

command curl -sSL https://rvm.io/mpapis.asc | gpg --import -

\curl -sSL https://get.rvm.io | bash -s stable

source $HOME/.rvm/scripts/rvm

rvm 

rvm install jruby-9.1.0.0

rvm use jruby-9.1.0.0 --default

gem install bundler

source nodeinstall.sh

cd ~/gamerist

source update_dev_redis.sh

cd ~/gamerist

curl -O https://www.rabbitmq.com/releases/rabbitmq-server/v3.5.7/rabbitmq-server_3.5.7-1_all.deb

sudo gdebi rabbitmq-server_3.5.7-1_all.deb

echo ""

echo "GAMERIST development setup complete"
echo "You must now manually install and set up:"

echo " * handlr environment with steam servers"
