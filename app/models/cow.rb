class Cow < ApplicationRecord
  belongs_to :tenant

  enum :phase, {
    calf: "calf",
    heifer: "heifer",
    young: "young",
    primiparous: "primiparous",
    multiparous: "multiparous"
  }, _validate: true

  validates :name, presence: true
  validates :ear_tag, presence: true, uniqueness: { scope: :tenant_id }
  validates :birth_date, presence: true
  validates :breed, presence: true
  validates :weight, presence: true, numericality: { greater_than: 0 }
  validates :phase, presence: true
  validates :active, inclusion: { in: [ true, false ] }
end
