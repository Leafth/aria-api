module Events
  class Weighing < BaseEvent
    private

    def event_type
      "weighing"
    end

    def data
      raw = params[:data] || {}

      {
        weight: raw[:weight]
      }.compact
    end

    def apply!(_event)
      cow.recalculate_weight!
    end

    def validate!
      raise invalid!("cow is inactive") unless cow.active?

      weight = data[:weight]

      raise invalid!("weight is required") if weight.blank?
      raise invalid!("invalid weight") if weight <= 0
    end

    def invalid!(message)
      event = Event.new
      event.errors.add(:data, message)

      ActiveRecord::RecordInvalid.new(event)
    end
  end
end
