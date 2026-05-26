class AddLastPregnancyInterruptionAtToCows < ActiveRecord::Migration[8.1]
  def change
    add_column :cows, :last_pregnancy_interruption_at, :datetime
  end
end
