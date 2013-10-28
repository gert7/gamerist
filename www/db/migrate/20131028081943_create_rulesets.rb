class CreateRulesets < ActiveRecord::Migration
  def change
    create_table :rulesets do |t|
      t.integer :map_id
      t.integer :playercount

      t.timestamps
    end
  end
end
