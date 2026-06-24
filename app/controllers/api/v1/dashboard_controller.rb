module Api
  module V1
    class DashboardController < BaseController
      include CurrentTenant
      include AuthenticateRequest

      def reproductive_summary
        render json: ::Dashboard::ReproductiveSummary.new(
          tenant: current_tenant
        ).call
      end

      def phase_summary
        render json: ::Dashboard::PhaseSummary.new(
          tenant: current_tenant
        ).call
      end

      def alerts
        render json: ::Dashboard::Alerts.new(
          tenant: current_tenant
        ).call
      end

      def reproductive_indicators
        render json: Dashboard::Events::ReproductiveIndicators.new(
          tenant: current_tenant,
          params: reproductive_indicators_params
        ).call
      end

      def event_counts
        render json: Dashboard::Events::CountSummary.new(
          tenant: current_tenant,
          range: event_counts_period_range.current
        ).call
      end

      private

      def reproductive_indicators_params
        params.permit(:period, :date_from, :date_to)
      end

      def event_counts_params
        params.permit(:period, :date_from, :date_to)
      end

      def event_counts_period_range
        Dashboard::PeriodRange.new(
          tenant: current_tenant,
          params: event_counts_params
        )
      end
    end
  end
end
