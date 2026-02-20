class CreateEncounters < ActiveRecord::Migration[6.1]
  def change
    create_table :encounters, primary_key: :encounter_id, id: :string, force: :cascade do |t|
      t.string   :patient_id,     null: false
      t.string   :provider_id,    null: false
      t.datetime :encounter_date, null: false
      t.string   :encounter_type, null: false
      t.json    :clinical_data,  default: {}
      t.string   :created_by,     null: false

      t.timestamps
    end

    add_index :encounters, :provider_id
  end
end
