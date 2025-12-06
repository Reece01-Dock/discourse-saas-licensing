class DiscourseSaas::PurchaseSerializer < ApplicationSerializer
  attributes :id,
             :expires_at,
             :active,
             :organisation_id,
             :license_package_id,
             :package,
             :user_id,
             :username,
             :package_name,
             :created_at

  def package
    DiscourseSaas::LicensePackageSerializer.new(
      object.license_package,
      scope: scope,
      root: false,
    )
  end

  def username
    object.user&.username
  end

  def package_name
    object.license_package&.name
  end
end
