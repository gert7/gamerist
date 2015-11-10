FROM jruby:9.0.3.0
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev git nodejs
RUN mkdir /myapp
WORKDIR /myapp
ADD . /myapp
ADD Gemfile_docker /myapp/Gemfile
RUN rm Gemfile.lock
RUN bundle install
RUN RAILS_ENV=production bundle exec rake assets:precompile --trace
CMD ["rails","server","-b","0.0.0.0"]
