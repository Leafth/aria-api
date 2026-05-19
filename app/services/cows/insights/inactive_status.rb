module Cows
  module Insights
    class InactiveStatus
      def initialize(cow:)
        @cow = cow
      end

      def call
        {
          inactivated_at: inactivated_at,
          inactivated_reason: inactivated_reason
        }
      end

      private

      attr_reader :cow

      def inactivated_at
        return nil if inactivation_event.blank?

        I18n.l(inactivation_event.occurred_at.to_date)
      end

      def inactivated_reason
        inactivation_event&.data&.dig("reason")
      end

      def inactivation_event
        @inactivation_event ||= cow.events
          .where(event_type: "inactivation")
          .order(occurred_at: :desc, created_at: :desc)
          .first
      end
    end
  end
end
