module DiscourseSaas
  module Admin
    class OrganisationsController < ::DiscourseSaas::ApplicationController
      requires_plugin ::DiscourseSaas::PLUGIN_NAME
      before_action :ensure_admin

      def index
        organisations = DiscourseSaas::Organisation.includes(:members, :group, :owner).order(created_at: :desc)
        render_serialized(organisations, DiscourseSaas::OrganisationSerializer, root: :organisations)
      end

      def show
        organisation = DiscourseSaas::Organisation.find(params[:id])
        render_serialized(organisation, DiscourseSaas::OrganisationSerializer, root: :organisation)
      end

      def invite
        organisation = DiscourseSaas::Organisation.find(params[:id])
        user = find_user_from_params
        raise Discourse::NotFound if user.blank?
        organisation.add_member!(user, added_by: current_user)
        render_serialized(organisation, DiscourseSaas::OrganisationSerializer, root: :organisation)
      end

      def remove_member
        organisation = DiscourseSaas::Organisation.find(params[:id])
        user = User.find_by(id: params[:user_id])
        raise Discourse::NotFound if user.blank?
        organisation.remove_member!(user)
        render_serialized(organisation, DiscourseSaas::OrganisationSerializer, root: :organisation)
      end

      private

      def ensure_admin
        guardian.ensure_can_admin_site!
      end

      def find_user_from_params
        identifier = params[:username_or_email]
        return if identifier.blank?

        User.find_by_username_or_email(identifier)
      end
    end
  end
end
