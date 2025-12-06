# frozen_string_literal: true

# name: discourse-saas-licensing
# about: SaaS licensing for individuals and organisations (payment-agnostic, BYO provider).
# version: 0.1.0
# authors: OpenAI Codex
# url: https://github.com/discourse/discourse-saas-licensing

enabled_site_setting :license_enabled

register_asset "stylesheets/saas-licensing.scss", :admin
register_asset "admin/index.js", :admin

module ::DiscourseSaas
  PLUGIN_NAME = "discourse-saas-licensing"

  def self.ensure_enabled!
    raise Discourse::InvalidAccess.new("Licensing disabled") if !SiteSetting.license_enabled
  end
end

after_initialize do
  require_relative "app/models/discourse_saas/license_package"
  require_relative "app/models/discourse_saas/purchase"
  require_relative "app/models/discourse_saas/organisation"
  require_relative "app/models/discourse_saas/organisation_member"
  require_relative "app/serializers/discourse_saas/license_package_serializer"
  require_relative "app/serializers/discourse_saas/purchase_serializer"
  require_relative "app/serializers/discourse_saas/organisation_member_serializer"
  require_relative "app/serializers/discourse_saas/organisation_serializer"
  require_relative "app/controllers/discourse_saas/application_controller"
  require_relative "app/controllers/discourse_saas/licenses_controller"
  require_relative "app/controllers/discourse_saas/admin/license_packages_controller"
  require_relative "app/controllers/discourse_saas/admin/organisations_controller"
  require_relative "app/controllers/discourse_saas/admin/purchases_controller"
  require_relative "app/controllers/discourse_saas/admin/settings_controller"
  require_relative "app/jobs/discourse_saas/license_expiry_job"

  module ::DiscourseSaas
    class Engine < ::Rails::Engine
      engine_name "discourse_saas"
      isolate_namespace DiscourseSaas
    end
  end

  DiscourseSaas::Engine.routes.draw do
    get "/license/user/:id" => "licenses#user"
    get "/license/org/:id" => "licenses#org"

    namespace :admin, constraints: AdminConstraint.new do
      resources :license_packages, path: "/license/packages", only: %i[index show create update destroy]
      resources :organisations, path: "/license/orgs", only: %i[index show] do
        post :invite, on: :member
        delete "member/:user_id", action: :remove_member, on: :member
      end
      resources :purchases, path: "/license/purchases", only: %i[index create destroy]
      resource :settings, only: %i[show update], controller: "settings", path: "/license/settings"
    end
  end

  Discourse::Application.routes.append do
    mount ::DiscourseSaas::Engine, at: "/saas"
  end

  add_admin_route "saas_licensing.title", "saas-licensing"

  add_to_class(:user, :active_license_packages) do
    DiscourseSaas::Purchase.active.where(user_id: id).includes(:license_package)
  end
end
