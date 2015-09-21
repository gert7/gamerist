sudo rm -rf node_modules
sudo npm install
PATH="$PATH:$HOME/gamerist/handlr/node_modules/.bin"
export PATH
cp package.json ../package.json
