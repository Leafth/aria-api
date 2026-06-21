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
    end
  end
end
