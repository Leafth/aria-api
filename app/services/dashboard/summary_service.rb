module Dashboard
  class SummaryService
    def initialize(tenant:)
      @tenant = tenant
    end

    def call
      active_counts = @tenant.cows.group(:active).count

      active_cows = active_counts[true] || 0
      inactive_cows = active_counts[false] || 0

      reproductive_counts = @tenant
        .cows
        .where(active: true)
        .group(:reproductive_status)
        .count

      counts = {
        total: active_cows + inactive_cows,
        active: active_cows,
        inactive: inactive_cows
      }

      Cow.reproductive_statuses.keys.each do |status|
        counts[status.to_sym] = reproductive_counts[status] || 0
      end

      {
        cows: counts
      }
    end
  end
end
