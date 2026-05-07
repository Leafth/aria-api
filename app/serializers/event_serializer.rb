class EventSerializer < ActiveModel::Serializer
  attributes :id, :event_type, :occurred_at, :cow_id, :data

  def occurred_at
    object.occurred_at&.strftime("%Y-%m-%d")
  end
end
