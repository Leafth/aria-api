class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name
      t.string :email
      t.string :password_digest
      t.integer :status
      t.datetime :last_sign_in_at

      t.timestamps
    end

    add_index :users, [ :tenant_id, :email ], unique: true
    add_index :users, :status
  end
end
