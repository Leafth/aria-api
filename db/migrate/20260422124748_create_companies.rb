class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies, id: :uuid do |t|
      t.string :name
      t.text :description
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end

    add_index :companies, [ :tenant_id, :name ]
  end
end
