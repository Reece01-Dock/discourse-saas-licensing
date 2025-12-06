module DiscourseSaas
  class Purchase < ActiveRecord::Base
    self.table_name = "discourse_saas_purchases"

    belongs_to :user
    belongs_to :license_package, class_name: "DiscourseSaas::LicensePackage"
    belongs_to :organisation, class_name: "DiscourseSaas::Organisation", optional: true

    scope :active, -> { where(active: true).where("expires_at > ?", Time.zone.now) }

    def expired?
      !active || expires_at <= Time.zone.now
    end

    def self.create_with_package(user:, license_package:, organisation_name: nil, expires_at: nil)
      expires_at ||= license_package.duration_days.days.from_now

      transaction do
        purchase =
          create!(
            user_id: user.id,
            license_package_id: license_package.id,
            expires_at: expires_at,
            active: true,
          )
        purchase.grant_access!
        purchase.create_org!(organisation_name) if license_package.is_org_license
        purchase
      end
    end

    def grant_access!
      GroupUser.find_or_create_by!(group_id: license_package.group_id, user_id: user_id)
    end

    def revoke_access!
      GroupUser.where(group_id: license_package.group_id, user_id: user_id).delete_all
    end

    def expire!
      return if expired?

      transaction do
        revoke_access!
        if organisation&.active?
          organisation.deactivate!
        end
        update!(active: false)
      end
    end

    def create_org!(organisation_name = nil)
      return organisation if organisation.present?

      package = license_package
      owner = user
      group =
        Group.create!(
          name: unique_group_name(owner, organisation_name || package.name),
          visibility_level: Group.visibility_levels[:staff],
        )

      org =
        DiscourseSaas::Organisation.create!(
          name: organisation_name.presence || package.name,
          owner_id: owner.id,
          group_id: group.id,
          seats_total: package.seats,
          seats_used: 0,
          active: true,
        )
      update!(organisation_id: org.id)
      org.add_member!(owner, added_by: owner)
      org
    end

    private

    def unique_group_name(owner, base_name)
      slug = base_name.to_s.parameterize.presence || "org"
      "org_#{slug}_#{owner.id}_#{SecureRandom.hex(2)}"
    end
  end
end
