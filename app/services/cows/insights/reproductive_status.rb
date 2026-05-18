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
          observation: observation
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

      def open_observation
        return I18n.t!("cows.insights.profile.reproductive_status.observations.open_without_heat") if cow.last_heat_at.blank?

        I18n.t!(
          "cows.insights.profile.reproductive_status.observations.open",
          next_heat_date: I18n.l(cow.last_heat_at.to_date + 21.days)
        )
      end

      def in_heat_observation
        remaining_hours = ((cow.last_heat_at + 24.hours - Time.current) / 1.hour).ceil

        return I18n.t!("cows.insights.profile.reproductive_status.observations.heat_expired") unless remaining_hours.positive?

        I18n.t!(
          "cows.insights.profile.reproductive_status.observations.in_heat",
          remaining_hours: remaining_hours
        )
      end

      def inseminated_observation
        I18n.t!(
          "cows.insights.profile.reproductive_status.observations.inseminated",
        )
      end

      def pregnant_observation
        I18n.t!(
          "cows.insights.profile.reproductive_status.observations.pregnant",
          calving_date: I18n.l(cow.last_insemination_at.to_date + 285.days)
        )
      end

      def postpartum_observation
        I18n.t!(
          "cows.insights.profile.reproductive_status.observations.postpartum",
          calving_date: I18n.l(cow.last_calving_at.to_date)
        )
      end
    end
  end
end
