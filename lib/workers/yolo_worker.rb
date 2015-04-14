class YoloWorker
  include Sidekiq::Worker
  sidekiq_options queue: "high"
  # sidekiq_options retry: false
      
  def perform(y)
    File.open("pepsi.txt", "a") do |f|
      f.write(y + "\n")
    end
  end
end

