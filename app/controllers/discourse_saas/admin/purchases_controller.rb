module DiscourseSaas
  module Admin
    class PurchasesController < ::DiscourseSaas::ApplicationController
      requires_plugin ::DiscourseSaas::PLUGIN_NAME
      before_action :ensure_admin

      def index
        purchases =
          DiscourseSaas::Purchase
            .includes(:license_package, :user)
            .order(created_at: :desc)
            .limit(200)
        render_serialized(purchases, DiscourseSaas::PurchaseSerializer, root: :purchases)
      end

      def create
        payload =
          params.require(:license).permit(:username_or_email, :package_id, :duration_days, :organisation_name)
        user = find_user(payload[:username_or_email])
        raise Discourse::NotFound if user.blank?

        package = DiscourseSaas::LicensePackage.find(payload[:package_id])
        if package.is_org_license && !SiteSetting.allow_org_licenses
          raise Discourse::InvalidAccess.new("Organisation licenses are disabled")
        end

        expires_at =
          if payload[:duration_days].present?
            payload[:duration_days].to_i.days.from_now
          else
            package.duration_days.days.from_now
          end

        purchase =
          DiscourseSaas::Purchase.create_with_package(
            user: user,
            license_package: package,
            organisation_name: payload[:organisation_name],
            expires_at: expires_at,
          )

        render_serialized(purchase, DiscourseSaas::PurchaseSerializer, root: :license)
      end

      def destroy
        purchase = DiscourseSaas::Purchase.find(params[:id])
        purchase.expire!
        render_json_dump(success: true)
      end

      private

      def ensure_admin
        guardian.ensure_can_admin_site!
      end

      def find_user(identifier)
        return if identifier.blank?

        User.find_by_username_or_email(identifier)
      end
    end
  end
end
