class AddBreedReference < ActiveRecord::Migration[8.1]
  def change
    add_reference :cows, :breed, null: false, foreign_key: true, type: :uuid
    add_reference :bulls, :breed, null: false, foreign_key: true, type: :uuid

    remove_column :cows, :breed, :string
    remove_column :bulls, :breed, :string
  end
end
