class CreateApiKeys < ActiveRecord::Migration[6.0]
  def change
    create_table :api_keys do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.string :key_name
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :api_keys, :token_digest
  end
end
