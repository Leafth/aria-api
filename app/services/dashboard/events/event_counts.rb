module Dashboard
  module Events
    class EventCounts
      DEFAULT_EVENT_TYPES = Event::REPRODUCTIVE_EVENT_TYPES

      def initialize(tenant:, range: nil, event_types: DEFAULT_EVENT_TYPES)
        @tenant = tenant
        @range = range
        @event_types = event_types
      end

      def call
        default_counts.merge(grouped_counts)
      end

      private

      attr_reader :tenant, :range, :event_types

      def grouped_counts
        events
          .group(:event_type)
          .count
          .transform_keys(&:to_s)
      end

      def default_counts
        event_types.index_with(0)
      end

      def events
        scope = Event.where(
          tenant: tenant,
          event_type: event_types
        )

        return scope unless range

        scope.where(occurred_at: range)
      end
    end
  end
end
