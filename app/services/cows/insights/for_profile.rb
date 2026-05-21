module Cows
  module Insights
    class ForProfile
      RECOMMENDED_NEXT_ACTIONS = {
        "open" => "heat_detection",
        "in_heat" => "insemination",
        "inseminated" => "pregnancy_check",
        "pregnant" => "calving",
        "postpartum" => "heat_detection"
      }.freeze

      def initialize(cow:)
        @cow = cow
      end

      def call
        {
          reproductive_status: reproductive_status,
          weight_insight: weight_insight,
          phase_insight: phase_insight,
          recommended_next_action: recommended_next_action
        }
      end

      private

      attr_reader :cow

      def reproductive_status
        Cows::Insights::ReproductiveStatus.new(cow: cow).call
      end

      def recommended_next_action
        RECOMMENDED_NEXT_ACTIONS[cow.reproductive_status]
      end

      def weight_insight
        {
          current_weight: cow.weight,
          last_weighing_at: last_weighing_at
        }
      end

      def phase_insight
        {
          current_phase: cow.phase,
          message: phase_message
        }
      end

      def phase_message
        return I18n.t!("cows.insights.profile.phase.below_weight") if below_weight_for_phase?

        if suggested_phase.present?
          return I18n.t!("cows.insights.profile.phase.change_suggested", phase: I18n.t!("activerecord.attributes.cow.phases.#{suggested_phase}"))
        end

        I18n.t!("cows.insights.profile.phase.adequate")
      end

      def below_weight_for_phase?
        return true if cow.phase == "heifer" && cow.weight < 100
        return true if cow.phase.in?(%w[young primiparous multiparous]) && cow.weight < 180

        false
      end

      def suggested_phase
        return "young" if cow.phase == "calf" && cow.weight >= 180
        return "heifer" if cow.phase == "calf" && cow.weight >= 100
        return "young" if cow.phase == "heifer" && cow.weight >= 180

        nil
      end

      def last_weighing_at
        cow.last_weighing_at
      end
    end
  end
end
