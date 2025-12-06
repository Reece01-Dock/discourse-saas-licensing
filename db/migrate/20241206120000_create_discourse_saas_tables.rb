class CreateDiscourseSaasTables < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_saas_license_packages do |t|
      t.string :name, null: false
      t.integer :price_cents, null: false, default: 0
      t.integer :duration_days, null: false, default: 30
      t.integer :seats, null: false, default: 1
      t.integer :group_id, null: false
      t.boolean :is_org_license, null: false, default: false
      t.timestamps
    end
    add_index :discourse_saas_license_packages, :group_id
    add_index :discourse_saas_license_packages, :is_org_license

    create_table :discourse_saas_organisations do |t|
      t.string :name, null: false
      t.integer :owner_id, null: false
      t.integer :group_id, null: false
      t.integer :seats_total, null: false, default: 1
      t.integer :seats_used, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :discourse_saas_organisations, :group_id
    add_index :discourse_saas_organisations, :owner_id
    add_index :discourse_saas_organisations, :active

    create_table :discourse_saas_purchases do |t|
      t.integer :user_id, null: false
      t.integer :license_package_id, null: false
      t.string :stripe_session_id
      t.datetime :expires_at, null: false
      t.integer :organisation_id
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :discourse_saas_purchases, :user_id
    add_index :discourse_saas_purchases, :license_package_id
    add_index :discourse_saas_purchases, :organisation_id
    add_index :discourse_saas_purchases, :expires_at
    add_index :discourse_saas_purchases, :active

    create_table :discourse_saas_organisation_members do |t|
      t.integer :organisation_id, null: false
      t.integer :user_id, null: false
      t.integer :added_by_id
      t.timestamps
    end
    add_index :discourse_saas_organisation_members, [:organisation_id, :user_id], unique: true, name: "idx_discourse_saas_org_members"
    add_index :discourse_saas_organisation_members, :user_id
  end
end
