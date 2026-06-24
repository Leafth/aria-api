module Dashboard
  module Events
    class ReproductiveIndicators
      def initialize(tenant:, params: {})
        @tenant = tenant
        @params = params.to_h.symbolize_keys
      end

      def call
        [
          insemination_success,
          heat_coverage,
          pregnancy_success
        ]
      end

      private

      attr_reader :tenant, :params

      def insemination_success
        build_rate(
          indicator: "insemination_success",
          successes: current_pregnancy_checks["positive"],
          failures: current_pregnancy_checks["negative"],
          previous_successes: previous_pregnancy_checks&.dig("positive"),
          previous_failures: previous_pregnancy_checks&.dig("negative")
        )
      end

      def heat_coverage
        build_rate(
          indicator: "heat_coverage",
          successes: current_event_counts["insemination"],
          failures: current_uncovered_heats,
          total: current_event_counts["heat_detection"],
          previous_successes: previous_event_counts&.dig("insemination"),
          previous_failures: previous_uncovered_heats,
          previous_total: previous_event_counts&.dig("heat_detection")
        )
      end

      def pregnancy_success
        build_rate(
          indicator: "pregnancy_success",
          successes: current_event_counts["calving"],
          failures: current_event_counts["pregnancy_interruption"],
          previous_successes: previous_event_counts&.dig("calving"),
          previous_failures: previous_event_counts&.dig("pregnancy_interruption")
        )
      end

      def build_rate(...)
        Dashboard::Events::Rate.new(...).call
      end

      def current_event_counts
        @current_event_counts ||= event_counts_for(period_range.current)
      end

      def previous_event_counts
        return nil unless period_range.previous

        @previous_event_counts ||= event_counts_for(period_range.previous)
      end

      def current_pregnancy_checks
        @current_pregnancy_checks ||= pregnancy_check_counts_for(period_range.current)
      end

      def previous_pregnancy_checks
        return nil unless period_range.previous

        @previous_pregnancy_checks ||= pregnancy_check_counts_for(period_range.previous)
      end

      def event_counts_for(range)
        Dashboard::Events::EventCounts.new(
          tenant: tenant,
          range: range
        ).call
      end

      def pregnancy_check_counts_for(range)
        Dashboard::Events::PregnancyCheckResultsCount.new(
          tenant: tenant,
          range: range
        ).call
      end

      def current_uncovered_heats
        [
          current_event_counts["heat_detection"] - current_event_counts["insemination"],
          0
        ].max
      end

      def previous_uncovered_heats
        return nil unless previous_event_counts

        [
          previous_event_counts["heat_detection"] - previous_event_counts["insemination"],
          0
        ].max
      end

      def period_range
        @period_range ||= Dashboard::PeriodRange.new(
          tenant: tenant,
          params: params
        )
      end
    end
  end
end
