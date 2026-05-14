module Events
  class ReproductiveTransitionValidator
    VALID_TRANSITIONS = {
      "heat_detection" => %i[
        reproductive_open?
        reproductive_postpartum?
      ],
      "insemination" => %i[
        reproductive_in_heat?
      ],
      "pregnancy_check" => %i[
        reproductive_inseminated?
      ],
      "calving" => %i[
        reproductive_pregnant?
      ]
    }.freeze

    def initialize(cow:, event_type:, data: {}, occurred_at: Time.current)
      @cow = cow
      @event_type = event_type
      @data = data || {}
      @occurred_at = occurred_at
    end

    def validate!
      allowed_states = VALID_TRANSITIONS[event_type]
      return true unless allowed_states

      return true if allowed_states.any? { |state| cow.public_send(state) }

      raise Events::Error, I18n.t!("events.errors.invalid_#{event_type}_transition")
    end

    private

    attr_reader :cow, :event_type, :data
  end
end
