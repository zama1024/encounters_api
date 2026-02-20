class CreateEncounters < ActiveRecord::Migration[6.1]
  def change
    create_table :encounters do |t|
      t.string :encounter_id,     null: false
      t.string   :patient_id,     null: false
      t.string   :provider_id,    null: false
      t.datetime :encounter_date, null: false
      t.string   :encounter_type, null: false
      t.json    :clinical_data,  default: {}
      t.json   :metadata,        default: {}

      t.timestamps
    end

    add_index :encounters, :provider_id
  end
end
