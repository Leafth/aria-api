module Events
    class Inactivation < BaseEvent
      VALID_REASONS = %w[sale death].freeze

      private

      def validate!
        raise invalid!(I18n.t!("cows.errors.cow_inactive")) unless cow.active?

        reason = data[:reason]

        raise invalid!(I18n.t!("events.inactivation.reason_required")) if reason.blank?
        raise invalid!(I18n.t!("events.inactivation.invalid_reason")) unless VALID_REASONS.include?(reason)
      end

      def apply!(_event)
        cow.update!(active: false)
      end

      def data
        raw = params[:data] || {}

        {
          reason: raw[:reason],
          observation: raw[:observation] || raw["observation"]
        }.compact
      end

      def event_type
        "inactivation"
      end

      def invalid!(message)
        Events::Error.new(message)
      end
    end
end
