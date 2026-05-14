module Events
    class BaseEvent
      def initialize(cow:, params:)
        @cow = cow
        @params = params
      end

      def call
        ActiveRecord::Base.transaction do
          validate!
          event = create_event
          apply!(event)
          event
        end
      end

      private

      attr_reader :cow, :params

      def create_event
        Event.create!(
          cow: cow,
          tenant: cow.tenant,
          event_type: event_type,
          occurred_at: occurred_at,
          data: data
        )
      end

      def occurred_at
        value = params[:occurred_at].presence || Time.current

        value.is_a?(String) ? Time.zone.parse(value) : value
      end

      def validate!
        validate_reproductive_chronology! if reproductive_event?
      end

      def validate_reproductive_chronology!
        Events::ReproductiveChronologyValidator.new(
          cow: cow,
          occurred_at: occurred_at
        ).validate!
      end

      def reproductive_event?
        event_type.in?(Event::REPRODUCTIVE_EVENT_TYPES)
      end

      def apply!(_event); end

      def data
        {}
      end

      def event_type
        raise NotImplementedError
      end
    end
end
