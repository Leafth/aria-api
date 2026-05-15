module Cows
  module Insights
    class ForProfile
      def initialize(cow:)
        @cow = cow
      end

      def call
        {
          weight_insight: weight_insight
        }
      end

      private

      attr_reader :cow

      def weight_insight
        {
          current_weight: cow.weight,
          last_weighing_at: last_weighing&.occurred_at
        }
      end

      def last_weighing
        @last_weighing ||= cow.events
          .where(event_type: "weighing")
          .order(occurred_at: :desc, created_at: :desc)
          .first
      end
    end
  end
end
