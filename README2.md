Adding maps
-----------

Maps are added at two places:

- www/config/games.yml
- smod_plugin/gamerist.sp

Bash scripts
------------

: denotes use of bash source (run in same bash instance, retain environment variables)

- handlr_setup.sh - set up handlr, does not run handlr
-- :nodeinstall.sh - install nodejs
--- :handlr/npminstall.sh - installs node dependencies and adds to PATH and .bash_profile
-- steamcmd.sh - installs steamcmd and all servers (very long)
- handlr/handlr.sh - exports bins to temp PATH and starts eternal pm2 instance with coffee-handlr
- handlr/run_tests.sh - exports bins to temp PATH and runs mocha test suite
- handlr_run.sh
-- handlr/handlr.sh
- start_development.sh - installs rvm with jruby and makes redis on Desktop
-- :nodeinstall.sh

