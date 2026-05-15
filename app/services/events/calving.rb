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
        phase: next_phase_after_calving,
        last_calving_at: occurred_at
      )
    end

    def next_phase_after_calving
      return "multiparous" if cow.phase.in?(%w[primiparous multiparous])

      "primiparous"
    end
  end
end
