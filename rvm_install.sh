if [ ! -d ~/.rvm ]; then
  command curl -sSL https://rvm.io/mpapis.asc | gpg --import -
  \curl -sSL https://get.rvm.io | bash -s stable
fi

source $HOME/.rvm/scripts/rvm

rvm

rvm install ruby-2.3.0

rvm use ruby-2.3.0 --default

gem install bundler

