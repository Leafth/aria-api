class AddReproductiveFieldsToCows < ActiveRecord::Migration[8.1]
  def change
    add_column :cows, :reproductive_status, :string, null: false, default: "open"
    add_column :cows, :last_heat_at, :datetime
    add_column :cows, :last_insemination_at, :datetime
    add_column :cows, :pregnancy_confirmed_at, :datetime
    add_column :cows, :last_calving_at, :datetime

    add_index :cows, :reproductive_status
  end
end
