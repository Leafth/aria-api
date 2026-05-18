module Cows
  module Insights
    class ReproductiveStatus
      def initialize(cow:)
        @cow = cow
      end

      def call
        {
          status: cow.reproductive_status,
          message: message
        }
      end

      private

      attr_reader :cow

      def message
        I18n.t!("cows.insights.profile.reproductive_status.messages.#{cow.reproductive_status}")
      end
    end
  end
end
