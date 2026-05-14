module Events
  class HeatDetectionWithInsemination
    def initialize(cow:, params:)
      @cow = cow
      @params = params
    end

    def call
      ActiveRecord::Base.transaction do
        heat_detection_event = Events::HeatDetection.new(
          cow: cow,
          params: heat_detection_params
        ).call

        cow.update!(reproductive_status: :in_heat)

        insemination_event = Events::Insemination.new(
          cow: cow,
          params: insemination_params
        ).call

        {
          heat_detection: heat_detection_event,
          insemination: insemination_event
        }
      end
    end

    private

    attr_reader :cow, :params

    def heat_detection_params
      {
        occurred_at: heat_occurred_at,
        data: heat_detection_data
      }
    end

    def insemination_params
      {
        occurred_at: insemination_occurred_at,
        data: insemination_data
      }
    end

    def heat_occurred_at
      value = params[:heat_occurred_at] || Time.current

      value.is_a?(String) ? Time.zone.parse(value) : value
    end

    def insemination_occurred_at
      value = params[:insemination_occurred_at] || Time.current

      value.is_a?(String) ? Time.zone.parse(value) : value
    end

    def heat_detection_data
      {
        observation: params.dig(:data, :heat_observation)
      }.compact
    end

    def insemination_data
      params.fetch(:data, {}).except(:heat_observation)
    end
  end
end
