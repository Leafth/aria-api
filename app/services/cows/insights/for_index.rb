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
          code: status_code,
          message: status_message,
          occurred_at: formatted_status_occurred_at
        }
      end

      def status_code
        return "weighing" if show_growth_status?

        reproductive_status[:status]
      end

      def status_message
        return I18n.t!("cows.insights.index.status.weighing") if show_growth_status?

        I18n.t!("cows.insights.index.status.#{cow.reproductive_status}")
      end

      def formatted_status_occurred_at
        return nil if status_occurred_at.blank?

        I18n.l(status_occurred_at.to_date)
      end

      def status_occurred_at
        return last_weighing if show_growth_status?

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
        return growth_phase_alert if show_growth_status?

        return if reproductive_status[:observation].blank?

        {
          level: "info",
          code: reproductive_status[:status],
          message: reproductive_status[:observation]
        }
      end

      def growth_phase_alert
        {
          level: "info",
          code: "phase_insight",
          message: phase_message
        }
      end

      def phase_message
        profile_insights.dig(:phase_insight, :message)
      end

      def last_weighing
        profile_insights.dig(:weight_insight, :last_weighing_at)
      end

      def profile_insights
        @profile_insights ||= Cows::Insights::ForProfile.new(cow: cow).call
      end

      def show_growth_status?
        cow.last_heat_at.blank?
      end

      def reproductive_status
        @reproductive_status ||= Cows::Insights::ReproductiveStatus.new(cow: cow).call
      end
    end
  end
end
