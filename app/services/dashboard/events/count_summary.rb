module Dashboard
  module Events
    class CountSummary
      def initialize(tenant:, range: nil)
        @tenant = tenant
        @range = range
      end

      def call
        event_counts.merge(pregnancy_check_results)
      end

      private

      attr_reader :tenant, :range

      def event_counts
        Dashboard::Events::EventCounts.new(
          tenant: tenant,
          range: range
        ).call
      end

      def pregnancy_check_results
        {
          "pregnancy_check_positive" => pregnancy_check_results_count["positive"],
          "pregnancy_check_negative" => pregnancy_check_results_count["negative"]
        }
      end

      def pregnancy_check_results_count
        @pregnancy_check_results_count ||= Dashboard::Events::PregnancyCheckResultsCount.new(
          tenant: tenant,
          range: range
        ).call
      end
    end
  end
end
