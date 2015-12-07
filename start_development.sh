REDIS_VERSION=redis-3.0.5

sudo apt-get install curl postgresql -y

command curl -sSL https://rvm.io/mpapis.asc | gpg --import -

\curl -sSL https://get.rvm.io | bash -s stable

source $HOME/.rvm/scripts/rvm

rvm install jruby-9.0.4.0

rvm use jruby-9.0.4.0 --default

gem install bundler

source nodeinstall.sh

\curl -O http://download.redis.io/releases/$REDIS_VERSION.tar.gz

mv redis-3.0.5.tar.gz $HOME/Desktop/$REDIS_VERSION.tar.gz

cd $HOME/Desktop

tar -xvf $REDIS_VERSION.tar.gz

rm $REDIS_VERSION.tar.gz

cd $REDIS_VERSION

make

