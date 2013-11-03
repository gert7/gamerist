set -e

find . -not -name '*.cnf' -not -name '*.sh' -not -name "README" | xargs rm
mkdir certs newcerts private
echo 3000 > serial
touch index.txt 

read -p "Now generating Certificate Authority"

openssl req -config ./openssl_ca.cnf -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=US/ST=Washington/L=Seattle/O=Gamerist/CN=authority" -keyout private/cakey.pem  -out authority.pem

read -p "Generating certificate for Rails"

openssl req -new -nodes -out rails-req.pem -keyout private/rails.key -subj "/C=US/ST=Washington/L=Seattle/O=Gamerist/CN=rails"

