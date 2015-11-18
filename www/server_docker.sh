sed "s/localhost/$DB_PORT_5432_TCP_ADDR/g" config/database.yml > config/database_tmp.yml
cp config/database_tmp.yml config/database.yml
bundle exec rails server puma -p 3000

