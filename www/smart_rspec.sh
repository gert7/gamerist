#! /bin/bash

RSPEC="rspec . -f d"

# Looking for nailgun
lsof -i :2113 > /dev/null
if [ $? == 0 ]; then
  RSPEC="jruby --ng -S $RSPEC"
fi

# Looking for spork
lsof -i :8989 > /dev/null
if [ $? == 0 ]; then
  RSPEC="$RSPEC --drb"
fi

CMD="$RSPEC $@"
echo $CMD
$CMD
