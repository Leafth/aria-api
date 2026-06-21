module Dashboard
  class ReproductiveSummary
    def initialize(tenant:)
      @tenant = tenant
    end

    def call
      active_cows = active_counts[true] || 0
      inactive_cows = active_counts[false] || 0

      counts = {
        total: active_cows + inactive_cows,
        active: active_cows,
        inactive: inactive_cows
      }

      Cow.reproductive_statuses.keys.each do |status|
        counts[status.to_sym] = reproductive_counts[status] || 0
      end

      counts
    end

    private

    attr_reader :tenant

    def active_counts
      @active_counts ||= tenant
        .cows
        .group(:active)
        .count
    end

    def reproductive_counts
      @reproductive_counts ||= tenant
        .cows
        .where(active: true)
        .group(:reproductive_status)
        .count
    end
  end
end
