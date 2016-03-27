REDIS_VERSION=redis-3.0.7

\curl -O http://download.redis.io/releases/$REDIS_VERSION.tar.gz

mv $REDIS_VERSION.tar.gz $HOME/Desktop/$REDIS_VERSION.tar.gz

cd $HOME/Desktop

tar -xvf $REDIS_VERSION.tar.gz

rm $REDIS_VERSION.tar.gz

cd $REDIS_VERSION/deps

make hiredis lua jemalloc linenoise

cd ..

make

rm $HOME/Desktop/$REDIS_VERSION/redis.conf
cp $HOME/gamerist/redis.conf $HOME/Desktop/$REDIS_VERSION/redis.conf
