module Dashboard
  class PhaseSummary
    def initialize(tenant:)
      @tenant = tenant
    end

    def call
      Cow.phases.keys.each_with_object({ total: total }) do |phase, counts|
        counts[phase.to_sym] = phase_counts[phase] || 0
      end
    end

    private

    attr_reader :tenant

    def cows
      @cows ||= tenant.cows.where(active: true)
    end

    def total
      @total ||= cows.count
    end

    def phase_counts
      @phase_counts ||= cows
        .group(:phase)
        .count
    end
  end
end
