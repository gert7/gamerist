NODE_PACKAGE_NAME=setup_4.x

curl -sOL https://deb.nodesource.com/$NODE_PACKAGE_NAME

sudo bash $NODE_PACKAGE_NAME

sudo apt-get install -y nodejs

cd handlr

./npminstall.sh

rm $NODE_PACKAGE_NAME
