CURL_O="-# --max-time 20 --retry 4"

mkdir steamcmd
cd steamcmd # CD gamerist/steamcmd
curl -O http://media.steampowered.com/installer/steamcmd_linux.tar.gz $CURL_O
tar -xvzf steamcmd_linux.tar.gz
rm steamcmd_linux.tar.gz
mkdir tf
mkdir css
mkdir cs_go
sleep 5
./steamcmd.sh +runscript ../steams.txt
sleep 1

if [ ! -f "mmsource-1.10.5-linux.tar.gz" ]; then
  curl -O http://mirror.pointysoftware.net/alliedmodders/mmsource-1.10.5-linux.tar.gz $CURL_O
fi
tar -xvzf mmsource-1.10.5-linux.tar.gz -C tf/tf

if [ ! -f "sourcemod-1.7.2-linux.tar.gz" ]; then
  curl -O http://mirror.pointysoftware.net/alliedmodders/sourcemod-1.7.2-linux.tar.gz $CURL_O
fi
tar -xvzf sourcemod-1.7.2-linux.tar.gz -C tf/tf

if [ ! -f "socket_3.0.1.zip" ]; then
  curl -O https://forums.alliedmods.net/attachment.php?attachmentid=83286\&d=1299423920 $CURL_O
fi

mkdir s_ocket
cp attachment.php?attachmentid=83286* socket_3.0.1.zip
rm attachment.php?attachmentid=83286*
unzip socket_3.0.1.zip -d s_ocket
rsync -aP s_ocket/* tf/tf/
rm -rf s_ocket
cp tf/tf/addons/sourcemod/plugins/* tf/tf/addons/sourcemod/plugins/disabled
rm tf/tf/addons/sourcemod/plugins/*
cd ../smod_plugin
./compile.sh
cd ../steamcmd
rsync -aP ../game_content/* .

