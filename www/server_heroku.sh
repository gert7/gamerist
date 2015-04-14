bundle exec rake db:migrate &
bundle exec rails server puma -p ${PORT} -e ${RACK_ENV}

