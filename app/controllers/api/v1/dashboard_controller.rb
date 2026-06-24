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
          params: dashboard_period_params
        ).call
      end

      def event_counts
        render json: Dashboard::Events::CountSummary.new(
          tenant: current_tenant,
          range: dashboard_period_range.current
        ).call
      end

      def reproductive_rates_evolution
        render json: Dashboard::Events::MonthlyRateEvolution.new(
          tenant: current_tenant
        ).call
      end

      def insemination_distribution
        render json: Dashboard::Events::InseminationDistribution.new(
          tenant: current_tenant,
          range: dashboard_period_range.current
        ).call
      end

      def reproductive_report
        pdf = Dashboard::Reports::ReproductivePdf.new(
          tenant: current_tenant,
          user: current_user,
          params: dashboard_period_params
        ).call

        send_data pdf,
          filename: reproductive_report_filename,
          type: "application/pdf",
          disposition: "attachment"
      end

      private

      def dashboard_period_params
        params.permit(:period, :date_from, :date_to)
      end

      def dashboard_period_range
        Dashboard::PeriodRange.new(
          tenant: current_tenant,
          params: dashboard_period_params
        )
      end

      def reproductive_report_filename
        date = Date.current.strftime("%Y-%m-%d")

        if params[:period].present?
          "relatorio-reprodutivo-#{params[:period]}-#{date}.pdf"
        else
          "relatorio-reprodutivo-#{date}.pdf"
        end
      end
    end
  end
end
