class Breed < ApplicationRecord
  belongs_to :tenant

  has_many :cows, dependent: :restrict_with_error
  has_many :bulls, dependent: :restrict_with_error

  validates :name, presence: true
  validates :normalized_name, presence: true, uniqueness: { scope: :tenant_id }

  before_validation :normalize_name

  private

  def normalize_name
    return if name.blank?

    self.name = name.strip.downcase.titleize
    self.normalized_name = name.parameterize
  end
end
