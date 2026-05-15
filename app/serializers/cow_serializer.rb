class CowSerializer < ActiveModel::Serializer
  attributes :id,
    :name,
    :ear_tag,
    :birth_date,
    :breed,
    :weight,
    :phase,
    :reproductive_status,
    :last_heat_at,
    :last_insemination_at,
    :last_calving_at,
    :active
end
