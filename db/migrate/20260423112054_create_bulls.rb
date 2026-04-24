class CreateBulls < ActiveRecord::Migration[8.1]
  def change
    create_table :bulls do |t|
      t.string :name, null: false
      t.string :breed, null: false
      t.string :origin, null: false
      t.string :ear_tag

      t.references :tenant, null: false, foreign_key: true
      t.references :company, type: :uuid, foreign_key: true

      t.timestamps
    end

    add_index :bulls, [ :tenant_id, :name ]

    add_index :bulls, [ :tenant_id, :ear_tag ],
      unique: true,
      where: "ear_tag IS NOT NULL"

    add_check_constraint :bulls,
      "origin IN ('local', 'company')",
      name: "bulls_origin_check"
  end
end
