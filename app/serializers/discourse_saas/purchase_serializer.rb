class DiscourseSaas::PurchaseSerializer < ApplicationSerializer
  attributes :id,
             :expires_at,
             :active,
             :organisation_id,
             :license_package_id,
             :package,
             :user_id

  def package
    DiscourseSaas::LicensePackageSerializer.new(
      object.license_package,
      scope: scope,
      root: false,
    )
  end
end
