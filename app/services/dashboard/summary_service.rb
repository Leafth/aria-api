module Dashboard
  class SummaryService
    def initialize(tenant:)
      @tenant = tenant
    end

    def call
      {
        reproductive_summary: cow_counts,
        phase_summary: phase_counts,
        alerts: alerts
      }
    end

    private

    attr_reader :tenant

    def cow_counts
      Dashboard::CountsService.new(tenant: tenant).call
    end

    def phase_counts
      Dashboard::PhaseCountsService.new(tenant: tenant).call
    end

    def alerts
      Cows::Alerts.new(tenant: tenant).call
    end
  end
end
