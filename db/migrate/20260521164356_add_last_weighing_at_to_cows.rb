class AddLastWeighingAtToCows < ActiveRecord::Migration[8.1]
  def change
    add_column :cows, :last_weighing_at, :datetime
  end
end
