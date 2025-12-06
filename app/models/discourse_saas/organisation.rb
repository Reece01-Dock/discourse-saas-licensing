module DiscourseSaas
  class Organisation < ActiveRecord::Base
    self.table_name = "discourse_saas_organisations"

    belongs_to :owner, class_name: "User"
    belongs_to :group
    has_many :members,
             class_name: "DiscourseSaas::OrganisationMember",
             foreign_key: :organisation_id,
             dependent: :destroy
    has_many :purchases, class_name: "DiscourseSaas::Purchase", dependent: :nullify

    validates :name, presence: true
    validates :seats_total, numericality: { greater_than_or_equal_to: 1 }

    def seats_available
      [seats_total - seats_used, 0].max
    end

    def active?
      active
    end

    def add_member!(user, added_by: nil)
      raise Discourse::InvalidAccess.new("Organisation inactive") if !active?
      raise Discourse::InvalidAccess.new("No seats available") if seats_available <= 0

      transaction do
        members.create!(user_id: user.id, added_by_id: added_by&.id)
        GroupUser.find_or_create_by!(group_id: group_id, user_id: user.id)
        increment!(:seats_used)
      end
    end

    def remove_member!(user)
      transaction do
        removed = members.where(user_id: user.id).destroy_all.length
        GroupUser.where(group_id: group_id, user_id: user.id).delete_all
        decrement!(:seats_used, removed) if removed.positive? && seats_used.positive?
      end
    end

    def deactivate!
      transaction do
        update!(active: false, seats_used: 0)
        remove_all_memberships!
      end
    end

    def remove_all_memberships!
      GroupUser.where(group_id: group_id).delete_all
      members.delete_all
      update_columns(seats_used: 0)
    end
  end
end
