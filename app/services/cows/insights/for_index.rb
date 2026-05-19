module Cows
  module Insights
    class ForIndex
      def initialize(cow:)
        @cow = cow
      end

      def call
        {
          status: status,
          alerts: alerts
        }
      end

      private

      attr_reader :cow

      def status
        {
          code: reproductive_status[:status],
          message: status_message,
          occurred_at: formatted_status_occurred_at
        }
      end

      def status_message
        I18n.t!("cows.insights.index.status.#{cow.reproductive_status}")
      end

      def formatted_status_occurred_at
        return nil if status_occurred_at.blank?

        I18n.l(status_occurred_at.to_date)
      end

      def status_occurred_at
        case cow.reproductive_status
        when "open", "in_heat"
          cow.last_heat_at
        when "inseminated"
          cow.last_insemination_at
        when "pregnant"
          cow.pregnancy_confirmed_at
        when "postpartum"
          cow.last_calving_at
        end
      end

      def alerts
        [ info_alert, *reproductive_status[:alerts] ].compact
      end

      def info_alert
        return if reproductive_status[:observation].blank?

        {
          level: "info",
          code: reproductive_status[:status],
          message: reproductive_status[:observation]
        }
      end

      def reproductive_status
        @reproductive_status ||= Cows::Insights::ReproductiveStatus.new(cow: cow).call
      end
    end
  end
end
