module Events
  class ReproductiveChronologyValidator
    def initialize(cow:, occurred_at:)
      @cow = cow
      @occurred_at = occurred_at
    end

    def validate!
      return true unless last_reproductive_event
      return true if occurred_at > last_reproductive_event.occurred_at

      raise Events::Error, i18n.t("events.errors.occurred_at_must_be_after_last_reproductive_event")
    end

    attr_reader :cow, :occurred_at

    def last_reproductive_event
      @last_reproductive_event ||= cow.events
        .reproductive
        .order(occurred_at: :desc, created_at: :desc)
        .first
    end
  end
end
