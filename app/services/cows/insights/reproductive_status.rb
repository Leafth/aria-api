module Cows
  module Insights
    class ReproductiveStatus
      def initialize(cow:)
        @cow = cow
      end

      def call
        {
          status: cow.reproductive_status,
          message: message,
          observation: observation,
          alerts: alerts
        }
      end

      private

      attr_reader :cow

      def message
        I18n.t!("cows.insights.profile.reproductive_status.messages.#{cow.reproductive_status}")
      end

      def observation
        case cow.reproductive_status
        when "open"
          open_observation
        when "in_heat"
          in_heat_observation
        when "inseminated"
          inseminated_observation
        when "pregnant"
          pregnant_observation
        when "postpartum"
          postpartum_observation
        end
      end

      def alerts
        case cow.reproductive_status
        when "open"
          open_alerts
        when "in_heat"
          in_heat_alerts
        when "inseminated"
          inseminated_alerts
        when "pregnant"
          pregnant_alerts
        else
          []
        end
      end

      def open_alerts
        [].tap do |items|
          items << open_heat_overdue_alert if open_heat_overdue?
        end.compact
      end

      def in_heat_alerts
        [].tap do |items|
          items << heat_ending_soon_alert if heat_ending_soon?
        end.compact
      end

      def inseminated_alerts
        [].tap do |items|
          items << pregnancy_check_due_alert if pregnancy_check_due?
          items << pregnancy_check_overdue_alert if pregnancy_check_overdue?
        end.compact
      end

      def pregnant_alerts
        [].tap do |items|
          items << calving_due_soon_alert if calving_due_soon?
          items << calving_overdue_alert if calving_overdue?
        end.compact
      end

      def open_observation
        return I18n.t!("cows.insights.profile.reproductive_status.observations.open_without_heat") if cow.last_heat_at.blank?

        I18n.t!(
          "cows.insights.profile.reproductive_status.observations.open",
          next_heat_date: I18n.l(expected_next_heat_date)
        )
      end

      def in_heat_observation
        return I18n.t!("cows.insights.profile.reproductive_status.observations.heat_expired") unless remaining_heat_hours.positive?

        I18n.t!(
          "cows.insights.profile.reproductive_status.observations.in_heat",
          remaining_hours: remaining_heat_hours
        )
      end

      def inseminated_observation
        I18n.t!(
          "cows.insights.profile.reproductive_status.observations.inseminated"
        )
      end

      def pregnant_observation
        I18n.t!(
          "cows.insights.profile.reproductive_status.observations.pregnant",
          calving_date: I18n.l(expected_calving_date)
        )
      end

      def postpartum_observation
        I18n.t!(
          "cows.insights.profile.reproductive_status.observations.postpartum",
          calving_date: I18n.l(cow.last_calving_at.to_date)
        )
      end

      def open_heat_overdue?
        cow.last_heat_at.present? && expected_next_heat_date < Date.current
      end

      def heat_ending_soon?
        remaining_heat_hours.between?(1, 8)
      end

      def pregnancy_check_due?
        days_since_insemination.between?(28, 30)
      end

      def pregnancy_check_overdue?
        days_since_insemination > 30
      end

      def calving_due_soon?
        expected_calving_date.present? && expected_calving_date.between?(Date.current, 15.days.from_now.to_date)
      end

      def calving_overdue?
        expected_calving_date.present? && expected_calving_date < Date.current
      end

      def open_heat_overdue_alert
        {
          level: "warning",
          code: "heat_overdue",
          message: I18n.t!("cows.insights.profile.reproductive_status.alerts.heat_overdue")
        }
      end

      def heat_ending_soon_alert
        {
          level: "warning",
          code: "heat_ending_soon",
          message: I18n.t!(
            "cows.insights.profile.reproductive_status.alerts.heat_ending_soon",
            remaining_hours: remaining_heat_hours
          )
        }
      end

      def pregnancy_check_due_alert
        {
          level: "warning",
          code: "pregnancy_check_due",
          message: I18n.t!("cows.insights.profile.reproductive_status.alerts.pregnancy_check_due")
        }
      end

      def pregnancy_check_overdue_alert
        {
          level: "danger",
          code: "pregnancy_check_overdue",
          message: I18n.t!("cows.insights.profile.reproductive_status.alerts.pregnancy_check_overdue")
        }
      end

      def calving_due_soon_alert
        {
          level: "warning",
          code: "calving_due_soon",
          message: I18n.t!("cows.insights.profile.reproductive_status.alerts.calving_due_soon")
        }
      end

      def calving_overdue_alert
        {
          level: "danger",
          code: "calving_overdue",
          message: I18n.t!("cows.insights.profile.reproductive_status.alerts.calving_overdue")
        }
      end

      def expected_next_heat_date
        cow.last_heat_at.to_date + 21.days
      end

      def remaining_heat_hours
        @remaining_heat_hours ||= ((cow.last_heat_at + 24.hours - Time.current) / 1.hour).ceil
      end

      def days_since_insemination
        return 0 if cow.last_insemination_at.blank?

        (Date.current - cow.last_insemination_at.to_date).to_i
      end

      def expected_calving_date
        return nil if cow.last_insemination_at.blank?

        cow.last_insemination_at.to_date + 285.days
      end
    end
  end
end
