class CowProfileSerializer < ActiveModel::Serializer
  attributes :id,
    :name,
    :ear_tag,
    :birth_date,
    :breed,
    :active,
    :insights

    def insights
      Cows::Insights::ForProfile.new(cow: object).call
    end
end
