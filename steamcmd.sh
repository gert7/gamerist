CURL_O="-# --max-time 20 --retry 4"

mkdir steamcmd
cd steamcmd # CD gamerist/steamcmd

SOURCEMOD_TARBALL="sourcemod-1.7.3-git5303-linux.tar.gz"
MMSOURCE_TARBALL="mmsource-1.10.6-linux.tar.gz"

sudo apt-get install lib32z1 gcc-multilib -y

curl -O http://media.steampowered.com/installer/steamcmd_linux.tar.gz $CURL_O
tar -xvzf steamcmd_linux.tar.gz
rm steamcmd_linux.tar.gz
mkdir tf
mkdir css
mkdir cs_go
sleep 5
./steamcmd.sh +runscript ../steams.txt
sleep 1

if [ ! -f $MMSOURCE_TARBALL ]; then
  curl -O http://mirror.pointysoftware.net/alliedmodders/$MMSOURCE_TARBALL $CURL_O
fi

mkdir mmsource_temp
tar -xvzf $MMSOURCE_TARBALL -C mmsource_temp
rsync -aP mmsource_temp/* tf/tf
rsync -aP mmsource_temp/* css/cstrike
rm -rf mmsource_temp

if [ ! -f $SOURCEMOD_TARBALL ]; then
  curl -O https://www.sourcemod.net/smdrop/1.7/$SOURCEMOD_TARBALL $CURL_O
fi

mkdir sourcemod_temp
tar -xvzf $SOURCEMOD_TARBALL -C sourcemod_temp
rsync -aP sourcemod_temp/* tf/tf
rsync -aP sourcemod_temp/* css/cstrike
rm -rf sourcemod_temp

if [ ! -f "socket_3.0.1.zip" ]; then
  curl -O https://forums.alliedmods.net/attachment.php?attachmentid=83286\&d=1299423920 $CURL_O
fi

mkdir s_ocket
cp attachment.php?attachmentid=83286* socket_3.0.1.zip
rm attachment.php?attachmentid=83286*
unzip socket_3.0.1.zip -d s_ocket
rsync -aP s_ocket/* tf/tf/
rsync -aP s_ocket/* css/cstrike/
rm -rf s_ocket
cp tf/tf/addons/sourcemod/plugins/* tf/tf/addons/sourcemod/plugins/disabled
rm tf/tf/addons/sourcemod/plugins/*
cp css/cstrike/addons/sourcemod/plugins/* css/cstrike/addons/sourcemod/plugins/disabled
rm css/cstrike/addons/sourcemod/plugins/*
cd ../smod_plugin
./compile.sh
cd ../steamcmd
rsync -aP ../game_content/* .

