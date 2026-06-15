module Dashboard
  class PhaseCountsService
    def initialize(tenant:)
      @tenant = tenant
    end

    def call
      Cow.phases.keys.each_with_object({}) do |phase, counts|
        counts[phase.to_sym] = phase_counts[phase] || 0
      end
    end

    private

    attr_reader :tenant

    def phase_counts
      @phase_counts ||= tenant
        .cows
        .where(active: true)
        .group(:phase)
        .count
    end
  end
end
