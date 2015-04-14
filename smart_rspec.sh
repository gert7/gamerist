#! /bin/bash

JRUBY="jruby --dev"
RSPEC="-S rspec -fd"

# Looking for nailgun
lsof -i :2113 > /dev/null
if [ $? == 0 ]; then
  JRUBY="$JRUBY --ng"
fi

# Looking for spork
lsof -i :8989 > /dev/null
if [ $? == 0 ]; then
  RSPEC="$RSPEC --drb"
fi

CMD="$JRUBY $RSPEC $@"
echo $CMD
$CMD