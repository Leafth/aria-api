module Dashboard
  module Events
    class EventCounts
      DEFAULT_EVENT_TYPES = Event::REPRODUCTIVE_EVENT_TYPES
      TOTAL_KEY = "total"

      def initialize(tenant:, range: nil, event_types: DEFAULT_EVENT_TYPES)
        @tenant = tenant
        @range = range
        @event_types = event_types
      end

      def call
        default_counts
          .merge(grouped_counts)
          .merge(TOTAL_KEY => total_count)
      end

      private

      attr_reader :tenant, :range, :event_types

      def grouped_counts
        events
          .group(:event_type)
          .count
          .transform_keys(&:to_s)
      end

      def total_count
        events.count
      end

      def default_counts
        event_types.index_with(0).merge(TOTAL_KEY => 0)
      end

      def events
        scoped_events.where(event_type: event_types)
      end

      def scoped_events
        scope = Event.where(tenant: tenant)

        return scope unless range

        scope.where(occurred_at: range)
      end
    end
  end
end
