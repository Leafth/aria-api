class BreedSerializer < ActiveModel::Serializer
  attributes :id, :name, :normalized_name
end
