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

      def index
        events = events_scope

        events = apply_filters(events)
        events = apply_sort(events)
        events = paginate(events)

        render_paginated events, serializer: params[:cow_id].present? ? EventSerializer : EventWithCowSerializer
      end

      def events_scope
        if params[:cow_id].present?
          current_tenant.cows.find(params[:cow_id]).events
        else
          Event
            .joins(:cow)
            .where(cows: { tenant_id: current_tenant.id })
        end
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
        when "pregnancy_interruption"
          Events::PregnancyInterruption.new(cow: cow, params: event_params)
        else
          event = Event.new
          event.errors.add(:event_type, I18n.t!("events.errors.unsupported_event_type"))

          raise ActiveRecord::RecordInvalid.new(event)
        end
      end

      def apply_filters(scope)
        scope = scope.reproductive if reproductive_filter?

        scope = scope.where(event_type: event_types_filter) if event_types_filter.present?
        scope = scope.where("occurred_at >= ?", params[:occurred_from]) if params[:occurred_from].present?
        scope = scope.where("occurred_at <= ?", params[:occurred_to]) if params[:occurred_to].present?
        scope = scope.where("created_at >= ?", params[:created_from]) if params[:created_from].present?
        scope = scope.where("created_at <= ?", params[:created_to]) if params[:created_to].present?

        scope
      end

      def apply_sort(scope)
        sort_by = params[:sort_by].presence || "occurred_at"
        sort_dir = params[:sort_dir] == "asc" ? :asc : :desc

        allowed_fields = %w[event_type occurred_at created_at updated_at]

        return scope.order(occurred_at: :desc) unless allowed_fields.include?(sort_by)

        scope.order(sort_by => sort_dir)
      end

      def paginate(scope)
        page = params[:page].to_i > 0 ? params[:page].to_i : 1
        per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 10

        scope.page(page).per(per_page)
      end

      def reproductive_filter?
        ActiveModel::Type::Boolean.new.cast(params[:reproductive])
      end

      def event_types_filter
        Array(params[:event_type])
          .flat_map { |event_type| event_type.to_s.split(",") }
          .map(&:strip)
          .reject(&:blank?)
      end
    end
  end
end
