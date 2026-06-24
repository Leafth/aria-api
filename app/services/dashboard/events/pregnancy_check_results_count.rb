module Dashboard
  module Events
    class PregnancyCheckResultsCount
      RESULTS = %w[
        positive
        negative
      ].freeze

      def initialize(tenant:, range: nil)
        @tenant = tenant
        @range = range
      end

      def call
        {
          "positive" => result_counts["positive"] || 0,
          "negative" => result_counts["negative"] || 0
        }
      end

      private

      attr_reader :tenant, :range

      def result_counts
        @result_counts ||= events
          .where(event_type: "pregnancy_check")
          .where("data ->> 'result' IN (?)", RESULTS)
          .group("data ->> 'result'")
          .count
      end

      def events
        scope = Event.where(tenant: tenant)

        return scope unless range

        scope.where(occurred_at: range)
      end
    end
  end
end
