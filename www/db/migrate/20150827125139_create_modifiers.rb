class CreateModifiers < ActiveRecord::Migration
  def change
    create_table :modifiers do |t|
      t.string :key
      t.string :value
      t.boolean :active
      t.boolean :recent

      t.timestamps null: false
    end
  end
end
