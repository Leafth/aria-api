class EventSerializer < ActiveModel::Serializer
  attributes :id, :event_type, :title, :occurred_at, :observation

  def title
    I18n.t!("activerecord.attributes.event.event_type.#{object.event_type}")
  end

  def occurred_at
    I18n.l(object.occurred_at.to_date)
  end

  def observation
    Events::ObservationBuilder.new(object).call
  end
end
