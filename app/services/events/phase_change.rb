module Events
  class PhaseChange < BaseEvent
    VALID_PHASES_TO_CHANGE = %w[
      calf
      heifer
      young
    ].freeze

    LOCKED_PHASES_TO_CHANGE = %w[
      primiparous
      multiparous
    ].freeze

    private

    def event_type
      "phase_change"
    end

    def data
      raw = params[:data] || {}

      {
        previous_phase: cow.phase,
        phase: raw[:phase]
      }.compact
    end

    def apply!(_event)
      cow.update!(phase: data[:phase])
    end

    def validate!
      raise invalid!("cow is inactive") unless cow.active?

      phase = data[:phase]

      raise invalid!("phase is required") if phase.blank?
      raise invalid!("invalid phase") unless Cow.phases.key?(phase)
      raise invalid!("current phase cannot be changed manually") if LOCKED_PHASES_TO_CHANGE.include?(cow.phase)
      raise invalid!("phase cannot be changed manually") unless VALID_PHASES_TO_CHANGE.include?(phase)
      raise invalid!("phase already is #{phase}") if cow.phase == phase
      raise invalid!("phase cannot go backwards") if phase_goes_backwards?(phase)
    end

    def phase_goes_backwards?(new_phase)
      current_index = VALID_PHASES_TO_CHANGE.index(cow.phase)
      new_index = VALID_PHASES_TO_CHANGE.index(new_phase)

      return false if current_index.nil?

      new_index < current_index
    end

    def invalid!(message)
      event = Event.new
      event.errors.add(:data, message)

      ActiveRecord::RecordInvalid.new(event)
    end
  end
end
