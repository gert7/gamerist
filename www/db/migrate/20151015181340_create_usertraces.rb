class CreateUsertraces < ActiveRecord::Migration
  def change
    create_table :usertraces do |t|
      t.user      :integer
      t.timestamp :datetime
      t.ipaddress :string
    end
  end
end
