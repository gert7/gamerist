export PATH=$PATH:$HOME/gamerist/handlr/node_modules/.bin
export PATH=$PATH:$PWD/node_modules/.bin

export DEBUG="maintain"
mocha --compilers coffee:coffee-script/register $1
