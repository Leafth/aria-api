module Events
  class PregnancyCheck < BaseEvent
    VALID_RESULTS = %w[
      positive
      negative
    ].freeze

    private

    def event_type
      "pregnancy_check"
    end

    def data
      {
        result: params.dig(:data, :result)
      }
    end

    def validate!
      super

      Events::ReproductiveTransitionValidator.new(
        cow: cow,
        event_type: event_type,
        data: data,
      ).validate!

      result = data[:result]

      raise Events::Error, I18n.t!("events.errors.pregnancy_check.result_required") if result.blank?
      raise Events::Error, I18n.t!("events.errors.pregnancy_check.invalid_result") unless VALID_RESULTS.include?(result)
    end

    def apply!(_event)
      cow.update!(reproductive_attrs)
    end

    def reproductive_attrs
      positive = data[:result] == "positive"

      {
        reproductive_status: positive ? "pregnant" : "open",
        pregnancy_confirmed_at: positive ? occurred_at : nil
      }
    end
  end
end
