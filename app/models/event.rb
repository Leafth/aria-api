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
    pregnancy_interruption
  ].freeze

  REPRODUCTIVE_EVENT_TYPES = %w[
    heat_detection
    insemination
    pregnancy_check
    calving
    pregnancy_interruption
  ].freeze

  scope :reproductive, -> { where(event_type: REPRODUCTIVE_EVENT_TYPES) }
  scope :ordered, -> { order(:occurred_at, :created_at) }

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  validates :occurred_at, presence: true

  validate :occurred_at_cannot_be_in_future
  validate :occurred_at_cannot_be_before_birth_date

  def reproductive?
    event_type.in?(REPRODUCTIVE_EVENT_TYPES)
  end

  private

  def occurred_at_cannot_be_in_future
    return unless occurred_at.present?

    if occurred_at > Time.current
      errors.add(:occurred_at, :future_date)
    end
  end

  def occurred_at_cannot_be_before_birth_date
    return unless occurred_at.present?

    errors.add(:occurred_at, :before_birth_date) if occurred_at < cow.birth_date
  end
end
