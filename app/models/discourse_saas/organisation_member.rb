module DiscourseSaas
  class OrganisationMember < ActiveRecord::Base
    self.table_name = "discourse_saas_organisation_members"

    belongs_to :organisation, class_name: "DiscourseSaas::Organisation"
    belongs_to :user
    belongs_to :added_by, class_name: "User", optional: true

    validates :user_id, uniqueness: { scope: :organisation_id }
  end
end
