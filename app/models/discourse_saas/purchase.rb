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
  end
end
