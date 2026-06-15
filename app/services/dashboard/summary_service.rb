# app/services/dashboard/summary_service.rb

module Dashboard
  class SummaryService
    def initialize(tenant:)
      @tenant = tenant
    end

    def call
      {
        summary: cow_counts,
        alerts: alerts
      }
    end

    private

    attr_reader :tenant

    def cow_counts
      Dashboard::CountsService.new(tenant: tenant).call
    end

    def alerts
      Cows::Alerts.new(tenant: tenant).call
    end
  end
end
