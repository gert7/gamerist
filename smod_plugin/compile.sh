cd $HOME/gamerist/smod_plugin
cp gamerist_tf.sp ../steamcmd/tf/tf/addons/sourcemod/scripting
cd ../steamcmd/tf/tf/addons/sourcemod/scripting
chmod ugo=rwx compile.sh
./compile.sh gamerist_tf.sp
cp compiled/gamerist_tf.smx ../plugins/gamerist.smx
rm -rf compiled

cd $HOME/gamerist/smod_plugin
cp gamerist_css.sp ../steamcmd/css/cstrike/addons/sourcemod/scripting
cd ../steamcmd/css/cstrike/addons/sourcemod/scripting
chmod ugo=rwx compile.sh
./compile.sh gamerist_css.sp
cp compiled/gamerist_css.smx ../plugins/gamerist.smx
rm -rf compiled

