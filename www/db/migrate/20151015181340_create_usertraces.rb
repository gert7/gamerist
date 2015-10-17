class CreateUsertraces < ActiveRecord::Migration
  def change
    create_table :usertraces do |t|
      t.integer   :user_id
      t.datetime  :timestamp
      t.string    :ipaddress
    end
  end
end

