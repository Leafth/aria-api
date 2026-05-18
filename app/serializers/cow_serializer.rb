class CowSerializer < ActiveModel::Serializer
  attributes :id,
    :name,
    :ear_tag,
    :birth_date,
    :breed,
    :weight,
    :phase,
    :reproductive_status,
    :active,
    :insights

    def insights
      Cows::Insights::ForIndex.new(cow: object).call
    end
end
