module DiscourseSaas
  module Admin
    class LicensePackagesController < ::DiscourseSaas::ApplicationController
      requires_plugin ::DiscourseSaas::PLUGIN_NAME

      before_action :ensure_admin

      def index
        render_serialized(
          DiscourseSaas::LicensePackage.all.order(:id),
          DiscourseSaas::LicensePackageSerializer,
          root: :license_packages,
        )
      end

      def show
        package = DiscourseSaas::LicensePackage.find(params[:id])
        render_serialized(package, DiscourseSaas::LicensePackageSerializer, root: :license_package)
      end

      def create
        package = DiscourseSaas::LicensePackage.create!(package_params)
        render_serialized(package, DiscourseSaas::LicensePackageSerializer, root: :license_package)
      end

      def update
        package = DiscourseSaas::LicensePackage.find(params[:id])
        package.update!(package_params)
        render_serialized(package, DiscourseSaas::LicensePackageSerializer, root: :license_package)
      end

      def destroy
        package = DiscourseSaas::LicensePackage.find(params[:id])
        package.destroy!
        render_json_dump(success: true)
      end

      private

      def ensure_admin
        guardian.ensure_can_admin_site!
      end

      def package_params
        params.require(:license_package).permit(
          :name,
          :price_cents,
          :duration_days,
          :seats,
          :group_id,
          :is_org_license,
        )
      end
    end
  end
end
