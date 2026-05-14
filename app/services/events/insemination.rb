module Events
  class Insemination < BaseEvent
    VALID_METHODS = %w[
      natural_mating
      artificial_insemination
    ].freeze

    private

    def event_type
      "insemination"
    end

    def data
      {
        method: params.dig(:data, :method),
        bull_id: params.dig(:data, :bull_id)
      }
    end

    def validate!
      super

      Events::ReproductiveTransitionValidator.new(
        cow: cow,
        event_type: event_type,
        data: data
      ).validate!

      method = data[:method]
      bull_id = data[:bull_id]
      bull = cow.tenant.bulls.find_by(id: bull_id)

      raise Events::Error, I18n.t!("events.errors.insemination.heat_expired") if cow.last_heat_at < occurred_at - 24.hours
      raise Events::Error, I18n.t!("events.errors.insemination.method_required") if method.blank?
      raise Events::Error, I18n.t!("events.errors.insemination.invalid_method") unless VALID_METHODS.include?(method)
      raise Events::Error, I18n.t!("events.errors.insemination.bull_required") if bull_id.blank?
      raise Events::Error, I18n.t!("events.errors.insemination.bull_not_found") if bull.blank?

      validate_method_matches_bull!(method, bull)
    end

    def apply!(_event)
      cow.update!(
        reproductive_status: "inseminated",
        last_insemination_at: occurred_at
      )
    end

    def validate_method_matches_bull!(method, bull)
      if method == "artificial_insemination" && !bull.company?
        raise Events::Error,
          I18n.t!("events.errors.insemination.artificial_insemination_requires_company_bull")
      end

      if method == "natural_mating" && !bull.local?
        raise Events::Error,
          I18n.t!("events.errors.insemination.natural_mating_requires_local_bull")
      end
    end
  end
end
