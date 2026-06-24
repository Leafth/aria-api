module Dashboard
  module Events
    class Rate
      def initialize(
        indicator:,
        successes:,
        failures:,
        previous_successes: nil,
        previous_failures: nil,
        total: nil,
        previous_total: nil
      )
        @indicator = indicator
        @successes = successes
        @failures = failures
        @total = total
        @previous_successes = previous_successes
        @previous_failures = previous_failures
        @previous_total = previous_total
      end

      def call
        {
          indicator: indicator,
          successes: successes,
          failures: failures,
          total: current_total,
          rate: percentage(successes, current_total),
          variation: variation
        }
      end

      private

      attr_reader :indicator, :successes, :failures, :total, :previous_successes, :previous_failures, :previous_total

      def current_total
        total || successes + failures
      end

      def calculated_previous_total
        previous_total || previous_successes + previous_failures
      end

      def variation
        return nil if previous_successes.nil? || previous_failures.nil?
        return nil if calculated_previous_total.zero?

        current_rate = percentage(successes, current_total)
        previous_rate = percentage(previous_successes, calculated_previous_total)

        (current_rate - previous_rate).round(2)
      end

      def percentage(value, total)
        return 0.0 if total.zero?

        ((value.to_f / total) * 100).round(2)
      end
    end
  end
end
