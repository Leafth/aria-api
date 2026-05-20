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

      return I18n.t!("events.observations.weighing.maintained") if diff.zero?

      key = diff.positive? ? "gained" : "lost"

      I18n.t!("events.observations.weighing.#{key}", weight: format(diff.abs))
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
