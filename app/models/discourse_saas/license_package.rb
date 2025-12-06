module DiscourseSaas
  class LicensePackage < ActiveRecord::Base
    self.table_name = "discourse_saas_license_packages"

    belongs_to :group
    has_many :purchases, class_name: "DiscourseSaas::Purchase"

    validates :name, presence: true
    validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :duration_days, numericality: { greater_than: 0 }
    validates :seats, numericality: { greater_than: 0 }
    validates :group_id, presence: true

    scope :organisation_only, -> { where(is_org_license: true) }
  end
end
