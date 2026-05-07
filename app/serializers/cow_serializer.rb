class CowSerializer < ActiveModel::Serializer
    attributes :id, :name, :ear_tag, :birth_date, :breed, :weight, :phase, :active
end
