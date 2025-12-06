module DiscourseSaas
  class LicensesController < ::DiscourseSaas::ApplicationController
    skip_before_action :verify_authenticity_token

    def user
      user = User.find_by(id: params[:id])
      raise Discourse::NotFound if user.blank?

      purchases = DiscourseSaas::Purchase.active.includes(:license_package).where(user_id: user.id)
      render_json_dump(
        user: BasicUserSerializer.new(user, scope: guardian, root: false),
        licenses: ActiveModel::Serializer::CollectionSerializer.new(
          purchases,
          serializer: DiscourseSaas::PurchaseSerializer,
        ),
        groups: user.groups.distinct.pluck(:name, :id).map { |name, id| { id: id, name: name } },
      )
    end

    def org
      organisation = DiscourseSaas::Organisation.includes(:members, :group).find_by(id: params[:id])
      raise Discourse::NotFound if organisation.blank?

      render_serialized(organisation, DiscourseSaas::OrganisationSerializer, root: :organisation)
    end
  end
end
