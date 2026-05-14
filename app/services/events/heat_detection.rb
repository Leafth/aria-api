module Events
  class HeatDetection < BaseEvent
    private

    def event_type
      "heat_detection"
    end

    def data
      {
        observation: params.dig(:data, :observation)
      }
    end

    def validate!
      super

      Events::ReproductiveTransitionValidator.new(
        cow: cow,
        event_type: event_type,
        data: data,
      ).validate!
    end

    def apply!(_event)
      cow.update!(
        reproductive_status: reproductive_status_after_heat,
        last_heat_at: occurred_at
      )
    end

    def reproductive_status_after_heat
        active_heat? ? "in_heat" : "open"
    end

    def active_heat?
        occurred_at >= Time.current - 24.hours
    end
  end
end
