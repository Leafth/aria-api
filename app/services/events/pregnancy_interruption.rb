module Events
  class PregnancyInterruption < BaseEvent
    private

    def event_type
      "pregnancy_interruption"
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
        reproductive_status: "open",
        last_pregnancy_interruption_at: occurred_at
      )
    end
  end
end
