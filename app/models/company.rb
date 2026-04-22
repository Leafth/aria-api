class Company < ApplicationRecord
  belongs_to :tenant

  validates :name, presence: true
end
