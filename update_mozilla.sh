export FFVERSION=42

curl -O http://releases.mozilla.org/pub/firefox/releases/$FFVERSION.0/linux-x86_64/en-GB/firefox-$FFVERSION.0.tar.bz2
tar -xjf firefox-$FFVERSION.0.tar.bz2
sudo mv firefox /opt/firefox$FFVERSION
rm firefox-$FFVERSION.0.tar.bz2

