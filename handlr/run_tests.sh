export PATH=$PATH:$HOME/gamerist/handlr/node_modules/.bin
export PATH=$PATH:$PWD/node_modules/.bin

mocha --compilers coffee:coffee-script/register
