class Event < ApplicationRecord
  belongs_to :cow
  belongs_to :tenant

  EVENT_TYPES = %w[
    inactivation
    weighing
    phase_change
  ].freeze

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
