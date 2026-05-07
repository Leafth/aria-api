class BullSerializer < ActiveModel::Serializer
  attributes :id, :name, :breed, :origin, :ear_tag, :company_id, :company

  def company
    return nil unless object.company

    {
      id: object.company.id,
      name: object.company.name
    }
  end
end
