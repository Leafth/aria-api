class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events, id: :uuid do |t|
      t.references :cow, type: :uuid, null: false, foreign_key: true
      t.references :tenant, type: :uuid, null: false, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :data, null: false, default: {}
      t.datetime :occurred_at, null: false

      t.timestamps
    end
  end
end
