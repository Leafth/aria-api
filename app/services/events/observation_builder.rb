# app/services/events/observation_builder.rb

module Events
  class ObservationBuilder
    def initialize(event)
      @event = event
    end

    def call
      case event.event_type
      when "weighing"
        weighing_observation
      when "phase_change"
        phase_change_observation
      when "inactivation"
        inactivation_observation
      else
        nil
      end
    end

    private

    attr_reader :event

    def weighing_observation
      weight = event.data["weight"].to_d
      previous_weight = previous_weighing&.data&.dig("weight")&.to_d

      return I18n.t!("events.observations.weighing.first", weight: format(weight)) unless previous_weight

      diff = weight - previous_weight

      return I18n.t!("events.observations.weighing.maintained", weight: format(weight)) if diff.zero?

      key = diff.positive? ? "gained" : "lost"

      I18n.t!("events.observations.weighing.#{key}", weight: format(diff.abs))
    end

    def phase_change_observation
      previous_phase = event.data["previous_phase"]
      phase = event.data["phase"]

      return nil if previous_phase.blank? || phase.blank?

      I18n.t!(
        "events.observations.phase_change",
        previous_phase: I18n.t!("activerecord.attributes.cow.phases.#{previous_phase}"),
        phase: I18n.t!("activerecord.attributes.cow.phases.#{phase}")
      )
    end

    def inactivation_observation
      reason = event.data["reason"]
      observation = event.data["observation"]

      return nil if reason.blank?

      text = I18n.t!(
        "events.observations.inactivation",
        reason: I18n.t!("events.inactivation.reasons.#{reason}")
      )

      return text if observation.blank?

      "#{text} - #{observation}"
    end

    def previous_weighing
      event.cow.events
        .where(event_type: "weighing")
        .where("occurred_at < ?", event.occurred_at)
        .order(occurred_at: :desc)
        .first
    end

    def format(value)
      value == value.to_i ? value.to_i : value
    end
  end
end
