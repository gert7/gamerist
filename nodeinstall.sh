NODE_PACKAGE_NAME=setup_6.x

if [ ! -f $NODE_PACKAGE_NAME ]; then
  curl -sOL https://deb.nodesource.com/$NODE_PACKAGE_NAME
fi

sudo bash $NODE_PACKAGE_NAME

sudo apt-get install -y nodejs
sudo apt-get dist-upgrade nodejs

cd handlr

sudo ln -s /usr/bin/nodejs /usr/bin/node

source npm_grab.sh

