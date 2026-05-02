module Events
    class Inactivation < BaseEvent
      VALID_REASONS = %w[sale death].freeze

      private

      def validate!
        reason = data[:reason] || data[:reason]

        raise invalid!("reason is required") if reason.blank?
        raise invalid!("invalid reason") unless VALID_REASONS.include?(reason)
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
        event = Event.new
        event.errors.add(:data, message)

        ActiveRecord::RecordInvalid.new(event)
      end
    end
end
