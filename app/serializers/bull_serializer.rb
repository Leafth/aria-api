class BullSerializer < ActiveModel::Serializer
  attributes :id, :name, :breed, :origin, :ear_tag, :company_id, :company

  def breed
    object.breed&.name
  end

  def company
    return nil unless object.company

    {
      id: object.company.id,
      name: object.company.name
    }
  end
end
