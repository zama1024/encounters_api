class CreateAuditAccesses < ActiveRecord::Migration[6.0]
  def change
    create_table :audit_accesses do |t|
      t.references :encounter, foreign_key: true, null: false
      t.integer :accessed_by_user_id, null: false
      t.datetime :accessed_at, null: false
    end

    add_index :audit_accesses, :accessed_at
  end
end
