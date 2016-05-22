REDIS_VERSION=redis-3.2.0

mkdir -p ~/Desktop

if [ ! -d ~/Desktop/$REDIS_VERSION ]; then
  \curl -O http://download.redis.io/releases/$REDIS_VERSION.tar.gz
  mv $REDIS_VERSION.tar.gz $HOME/Desktop/$REDIS_VERSION.tar.gz
  cd $HOME/Desktop
  tar -xvf $REDIS_VERSION.tar.gz
  rm $REDIS_VERSION.tar.gz
  cd $REDIS_VERSION/deps
  make hiredis lua jemalloc linenoise
  cd ..
  make
fi

rm $HOME/Desktop/$REDIS_VERSION/redis.conf
cp $HOME/gamerist/redis.conf $HOME/Desktop/$REDIS_VERSION/redis.conf
