class CreateTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants do |t|
      t.string :name
      t.string :slug
      t.integer :status

      t.timestamps
    end

    add_index :tenants, :slug, unique: true
    add_index :tenants, :status
  end
end
