ActiveRecord::Schema.define do
  self.verbose = false

  create_table :addresses, force: true do |t|
    t.string :street
    t.string :city
    t.string :state
    t.string :zip
    t.timestamps null: false
  end

  create_table :activities, force: true do |t|
    t.integer  :operator_id
    t.integer  :auditable_id
    t.string   :auditable_type
    t.string   :action
    t.text     :content
    t.datetime :created_at
  end
end
