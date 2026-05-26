class CreateBreeds < ActiveRecord::Migration[8.1]
  def change
    create_table :breeds, id: :uuid do |t|
      t.references :tenant, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :normalized_name, null: false

      t.timestamps
    end

    add_index :breeds, [ :tenant_id, :normalized_name ], unique: true
  end
end
