FROM jruby:9.0.1.0
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev git nodejs
RUN mkdir /myapp
WORKDIR /myapp
ADD Gemfile_docker /myapp/Gemfile
RUN bundle install
ADD . /myapp
ADD Gemfile_docker /myapp/Gemfile
