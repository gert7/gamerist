psql -c "DROP ROLE gamerist;"
psql -c "CREATE ROLE gamerist WITH CREATEDB LOGIN PASSWORD 'password';"

