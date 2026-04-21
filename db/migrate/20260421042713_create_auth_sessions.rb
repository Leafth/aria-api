class CreateAuthSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :auth_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.string :refresh_token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :auth_sessions, :refresh_token_digest, unique: true
    add_index :auth_sessions, :expires_at
    add_index :auth_sessions, :revoked_at
  end
end
