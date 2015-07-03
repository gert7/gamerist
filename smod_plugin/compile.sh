cp gamerist.sp ../steamcmd/tf/tf/addons/sourcemod/scripting
cd ../steamcmd/tf/tf/addons/sourcemod/scripting
chmod ugo=rwx compile.sh
./compile.sh gamerist.sp
cp compiled/gamerist.smx ../plugins/gamerist.smx
rm -rf compiled

