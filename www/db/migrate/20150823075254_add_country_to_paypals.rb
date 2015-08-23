class AddCountryToPaypals < ActiveRecord::Migration
  def change
    add_column :paypals, :country, :text
  end
end
