class Cow < ApplicationRecord
  belongs_to :tenant
  has_many :events, dependent: :destroy

  include HasTenantBreed

  enum :phase, {
    calf: "calf",
    heifer: "heifer",
    young: "young",
    primiparous: "primiparous",
    multiparous: "multiparous"
  }, validate: { message: :invalid_phase }

  enum :reproductive_status, {
    open: "open",
    in_heat: "in_heat",
    inseminated: "inseminated",
    pregnant: "pregnant",
    postpartum: "postpartum"
  }, prefix: :reproductive, validate: true

  validates :name, presence: true
  validates :ear_tag, presence: true, uniqueness: { scope: :tenant_id }
  validates :birth_date, presence: true
  validates :weight, presence: true, numericality: { greater_than: 0 }
  validates :phase, presence: true
  validates :reproductive_status, presence: true
  validates :active, inclusion: { in: [ true, false ] }

  validate :birth_date_cannot_be_in_future

  def birth_date_cannot_be_in_future
    return unless birth_date.present?

    errors.add(:birth_date, :future_date) if birth_date > Date.current
  end

  def weight_from_history
     events
      .where(event_type: "weighing")
      .order(occurred_at: :desc, created_at: :desc)
      .first
  end

  def recalculate_weight!
    last_weighing = weight_from_history

    update!(
      weight: last_weighing&.data&.dig("weight")&.to_f || weight,
      last_weighing_at: last_weighing&.occurred_at
    )
  end
end
