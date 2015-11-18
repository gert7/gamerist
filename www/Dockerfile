FROM jruby:9.0.4.0
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev git nodejs
RUN mkdir /myapp
WORKDIR /tmp
ADD Gemfile_docker /tmp/Gemfile
ADD Gemfile.lock /tmp/Gemfile.lock
RUN bundle install
WORKDIR /myapp
ADD . /myapp
# RUN RAILS_ENV=production bundle exec rake assets:precompile --trace
CMD bundle exec rake db:create db:migrate
CMD ["./server_docker.sh"]
