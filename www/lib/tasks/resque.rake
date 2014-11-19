require 'resque/tasks'

task "resque:setup" => :environment do
    require 'resque'
    # require 'jobs'
    ENV['QUEUE'] = "*"
    Resque.before_fork = Proc.new { ActiveRecord::Base.establish_connection }
end
