module Events
  class Calving < BaseEvent
    private

    def event_type
      "calving"
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
        reproductive_status: "postpartum",
        last_calving_at: occurred_at
      )
    end
  end
end
