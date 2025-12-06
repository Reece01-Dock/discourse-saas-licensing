module DiscourseSaas
  module Admin
    class SettingsController < ::DiscourseSaas::ApplicationController
      requires_plugin ::DiscourseSaas::PLUGIN_NAME
      skip_before_action :ensure_enabled, only: %i[index update]
      before_action :ensure_admin

      PLUGIN_SETTINGS = %i[license_enabled].freeze

      def index
        render_json_dump(settings: settings_hash)
      end

      def update
        settings = params.require(:settings).permit(PLUGIN_SETTINGS)
        settings.each do |key, value|
          next if !PLUGIN_SETTINGS.include?(key.to_sym)
          SiteSetting.public_send("#{key}=", value)
        end
        render_json_dump(settings: settings_hash)
      end

      private

      def ensure_admin
        guardian.ensure_can_admin_site!
      end

      def settings_hash
        PLUGIN_SETTINGS.index_with { |k| SiteSetting.public_send(k) }
      end
    end
  end
end
