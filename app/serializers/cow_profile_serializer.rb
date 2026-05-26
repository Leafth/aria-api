class CowProfileSerializer < ActiveModel::Serializer
  attributes :id,
    :name,
    :ear_tag,
    :birth_date,
    :breed,
    :active,
    :insights

    attribute :inactive_status, unless: :active?

    def breed
      object.breed&.name
    end

    def insights
      Cows::Insights::ForProfile.new(cow: object).call
    end

    def inactive_status
      Cows::Insights::InactiveStatus.new(cow: object).call
    end

    def active?
      object.active?
    end
end
