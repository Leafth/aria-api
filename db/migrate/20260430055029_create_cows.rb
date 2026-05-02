class CreateCows < ActiveRecord::Migration[8.1]
  def change
    create_table :cows, id: :uuid do |t|
      t.string :name, null: false
      t.string :ear_tag, null: false
      t.date :birth_date, null: false
      t.string :breed, null: false
      t.decimal :weight, precision: 10, scale: 2, null: false
      t.string :phase, null: false
      t.boolean :active, null: false, default: true
      t.references :tenant, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end

    add_index :cows, [ :tenant_id, :ear_tag ], unique: true
  end
end
