class EventSerializer < ActiveModel::Serializer
  attributes :id, :event_type, :occurred_at, :observation

  def occurred_at
    object.occurred_at&.strftime("%Y-%m-%d")
  end

  def observation
    Events::ObservationBuilder.new(object).call
  end
end
