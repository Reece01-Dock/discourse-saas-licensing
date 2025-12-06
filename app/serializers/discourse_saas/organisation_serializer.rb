class DiscourseSaas::OrganisationSerializer < ApplicationSerializer
  attributes :id,
             :name,
             :owner_id,
             :group_id,
             :seats_total,
             :seats_used,
             :seats_available,
             :active,
             :created_at,
             :updated_at,
             :members

  def members
    ActiveModel::Serializer::CollectionSerializer.new(
      object.members.includes(:user),
      serializer: DiscourseSaas::OrganisationMemberSerializer,
    )
  end

  def seats_available
    object.seats_available
  end
end
