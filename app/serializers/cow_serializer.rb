class CowSerializer < ActiveModel::Serializer
  attributes :id,
    :name,
    :ear_tag,
    :birth_date,
    :breed,
    :weight,
    :phase,
    :reproductive_status,
    :active

    attribute :insights, if: :active?
    attribute :inactive_status, unless: :active?

    def insights
      Cows::Insights::ForIndex.new(cow: object).call
    end

    def inactive_status
      Cows::Insights::InactiveStatus.new(cow: object).call unless object.active?
    end

    def active?
      object.active?
    end
end
