class Company < ApplicationRecord
  belongs_to :tenant
  has_many :bulls

  validates :name, presence: true
end
