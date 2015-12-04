echo "Enter the name of the Handlr instance and press ENTER:"
read handlrname

echo "Enter the full address of the RabbitMQ server and press ENTER:"
read mqhost

# exclamation marks used here in place of /
sed "s/centurion/$handlrname/g; s!amqp:\/\/127\.0\.0\.1!${mqhost}!g" handlr/config.json > handlr/config_temp.json

# cp config_temp.json config.json

source nodeinstall.sh
./steamcmd.sh

