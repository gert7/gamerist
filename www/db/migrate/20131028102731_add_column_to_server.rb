class AddColumnToServer < ActiveRecord::Migration
  def change
    add_column :servers, :game_id, :integer
  end
end
