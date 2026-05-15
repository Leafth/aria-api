module Api
  module V1
    class EventsController < BaseController
      include CurrentTenant
      include AuthenticateRequest

      def create
        cow = current_tenant.cows.find(params[:cow_id])

        event = build_event(cow).call

        render json: event, status: :created
      end

      private

      def build_event(cow)
        event_params = params.require(:event).permit(
          :event_type,
          :occurred_at,
          :heat_occurred_at,
          :insemination_occurred_at,
          data: {}
        )

        case event_params[:event_type]
        when "inactivation"
          Events::Inactivation.new(cow: cow, params: event_params)
        when "weighing"
          Events::Weighing.new(cow: cow, params: event_params)
        when "phase_change"
          Events::PhaseChange.new(cow: cow, params: event_params)
        when "heat_detection"
          Events::HeatDetection.new(cow: cow, params: event_params)
        when "insemination"
          Events::Insemination.new(cow: cow, params: event_params)
        when "heat_detection_with_insemination"
          Events::HeatDetectionWithInsemination.new(cow: cow, params: event_params)
        when "pregnancy_check"
          Events::PregnancyCheck.new(cow: cow, params: event_params)
        when "calving"
          Events::Calving.new(cow: cow, params: event_params)
        else
          event = Event.new
          event.errors.add(:event_type, I18n.t!("events.errors.unsupported_event_type"))

          raise ActiveRecord::RecordInvalid.new(event)
        end
      end
    end
  end
end
