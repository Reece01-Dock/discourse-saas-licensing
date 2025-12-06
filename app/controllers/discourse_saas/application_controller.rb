module DiscourseSaas
  class ApplicationController < ::ApplicationController
    requires_plugin ::DiscourseSaas::PLUGIN_NAME
    before_action :ensure_enabled

    private

    def ensure_enabled
      return if SiteSetting.license_enabled
      return if current_user&.staff?

      ::DiscourseSaas.ensure_enabled!
    end
  end
end
