class DiscourseSaas::LicensePackageSerializer < ApplicationSerializer
  attributes :id,
             :name,
             :price_cents,
             :duration_days,
             :seats,
             :group_id,
             :is_org_license,
             :created_at,
             :updated_at
end
