sudo rm -rf node_modules

sudo npm install

cp package.json ../package.json

export PATH=$PATH:$HOME/gamerist/handlr/node_modules/.bin

if [ ! -f ".npm_path_remembered" ]; then
  echo '' >>~/.bash_profile
  echo 'export PATH=$PATH:$HOME/gamerist/handlr/node_modules/.bin' >>~/.bash_profile
  touch .npm_path_remembered
  date +%s | cat > .npm_path_remembered
fi

