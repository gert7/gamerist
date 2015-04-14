set -e

find * -not -name '*.cnf' -not -name '*.sh' -not -name "README" | xargs rm -rf
mkdir certs newcerts private
echo 3000 > serial
touch index.txt 

echo "Now generating Certificate Authority"

openssl req -config ./openssl_ca.cnf -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=US/ST=Washington/L=Seattle/O=Gamerist/CN=authority" -keyout private/cakey.pem  -out authority.pem

echo "Generating certificate for Rails"

openssl req -new -nodes -out rails-req.pem -keyout private/rails-key.pem -subj "/C=US/ST=Washington/L=Seattle/O=Gamerist/CN=rails"

echo "Signing Rails request"

openssl ca -config ./openssl_ca.cnf -in rails-req.pem -out rails.pem -batch
