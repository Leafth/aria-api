class CowProfileSerializer < ActiveModel::Serializer
  attributes :id,
    :name,
    :ear_tag,
    :birth_date,
    :breed,
    :phase,
    :reproductive_status,
    :last_heat_at,
    :last_insemination_at,
    :last_calving_at,
    :active,
    :insights

    def insights
      Cows::Insights::ForProfile.new(cow: object).call
    end
end
