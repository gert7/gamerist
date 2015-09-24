class AddGamesToUser < ActiveRecord::Migration
  def change
    add_column :users, :relevantgames, :text
  end
end

