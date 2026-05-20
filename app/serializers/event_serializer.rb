class EventSerializer < ActiveModel::Serializer
  attributes :id, :event_type, :title, :occurred_at, :observation

  def title
    I18n.t!("activerecord.attributes.event.event_type.#{object.event_type}")
  end

  def occurred_at
    object.occurred_at&.strftime("%Y-%m-%d")
  end

  def observation
    Events::ObservationBuilder.new(object).call
  end
end
