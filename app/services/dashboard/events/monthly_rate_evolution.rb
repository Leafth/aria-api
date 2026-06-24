module Dashboard
  module Events
    class MonthlyRateEvolution
      MONTHS_COUNT = 12

      def initialize(tenant:)
        @tenant = tenant
      end

      def call
        month_ranges.map do |range|
          counts = event_counts_for(range)
          pregnancy_results = pregnancy_check_results_for(range)

          {
            month: range.begin.strftime("%Y-%m"),
            insemination_success: insemination_success_rate(pregnancy_results),
            heat_coverage: heat_coverage_rate(counts),
            pregnancy_success: pregnancy_success_rate(counts)
          }
        end
      end

      private

      attr_reader :tenant

      def insemination_success_rate(pregnancy_results)
        rate(
          successes: pregnancy_results["positive"],
          failures: pregnancy_results["negative"]
        )
      end

      def heat_coverage_rate(counts)
        heat_detections = counts["heat_detection"]
        inseminations = counts["insemination"]

        rate(
          successes: inseminations,
          failures: [ heat_detections - inseminations, 0 ].max,
          total: heat_detections
        )
      end

      def pregnancy_success_rate(counts)
        rate(
          successes: counts["calving"],
          failures: counts["pregnancy_interruption"]
        )
      end

      def rate(successes:, failures:, total: nil)
        Dashboard::Events::Rate.new(
          indicator: nil,
          successes: successes,
          failures: failures,
          total: total
        ).call[:rate]
      end

      def event_counts_for(range)
        Dashboard::Events::EventCounts.new(
          tenant: tenant,
          range: range
        ).call
      end

      def pregnancy_check_results_for(range)
        Dashboard::Events::PregnancyCheckResultsCount.new(
          tenant: tenant,
          range: range
        ).call
      end

      def month_ranges
        months.map do |date|
          date.beginning_of_month.beginning_of_day..date.end_of_month.end_of_day
        end
      end

      def months
        first_month = today.beginning_of_month - (MONTHS_COUNT - 1).months

        MONTHS_COUNT.times.map do |index|
          first_month + index.months
        end
      end

      def today
        Time.zone.today
      end
    end
  end
end
