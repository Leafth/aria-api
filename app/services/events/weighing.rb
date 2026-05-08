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
      raise invalid!(I18n.t!("cows.errors.cow_inactive")) unless cow.active?

      weight = data[:weight]

      raise invalid!(I18n.t!("events.weighing.weight_required")) if weight.blank?
      raise invalid!(I18n.t!("events.weighing.invalid_weight")) if weight <= 0
    end

    def invalid!(message)
      event = Event.new
      event.errors.add(:data, message)

      ActiveRecord::RecordInvalid.new(event)
    end
  end
end
