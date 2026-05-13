class Event < ApplicationRecord
  belongs_to :cow
  belongs_to :tenant

  EVENT_TYPES = %w[
    inactivation
    weighing
    phase_change

    heat_detection
    insemination
    pregnancy_check
    calving
  ].freeze

  REPRODUCTIVE_EVENT_TYPES = [
    EVENT_TYPES[:heat_detection],
    EVENT_TYPES[:insemination],
    EVENT_TYPES[:pregnancy_check],
    EVENT_TYPES[:calving]
  ].freeze

  scope :reproductive, -> { where(event_type: REPRODUCTIVE_EVENT_TYPES) }
  scope :ordered, -> { order(:occurred_at, :created_at) }

  def reproductive?
    event_type.in?(REPRODUCTIVE_EVENT_TYPES)
  end

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  validates :occurred_at, presence: true

  validate :occurred_at_cannot_be_in_future

  private

  def occurred_at_cannot_be_in_future
    return unless occurred_at.present?

    if occurred_at > Time.current
      errors.add(:occurred_at, :future_date)
    end
  end
end
