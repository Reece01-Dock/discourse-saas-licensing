class DiscourseSaas::OrganisationMemberSerializer < ApplicationSerializer
  attributes :id, :organisation_id, :user_id, :username, :added_by_id, :created_at

  def username
    object.user&.username
  end
end
