class Cow < ApplicationRecord
  belongs_to :tenant
  has_many :events, dependent: :destroy

  enum :phase, {
    calf: "calf",
    heifer: "heifer",
    young: "young",
    primiparous: "primiparous",
    multiparous: "multiparous"
  }, validate: { message: "invalid phase" }

  validates :name, presence: true
  validates :ear_tag, presence: true, uniqueness: { scope: :tenant_id }
  validates :birth_date, presence: true
  validates :breed, presence: true
  validates :weight, presence: true, numericality: { greater_than: 0 }
  validates :phase, presence: true
  validates :active, inclusion: { in: [ true, false ] }

  def weight_from_history
    last_weighing = events
      .where(event_type: "weighing")
      .order(occurred_at: :desc, created_at: :desc)
      .first

    last_weighing&.data&.dig("weight")&.to_f || weight
  end

  def recalculate_weight!
    update!(weight: weight_from_history)
  end
end
