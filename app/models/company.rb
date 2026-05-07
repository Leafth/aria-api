class Company < ApplicationRecord
  belongs_to :tenant
  has_many :bulls, dependent: :restrict_with_error

  validates :name, presence: true
end
