class Tenant < ApplicationRecord
  has_many :users, dependent: :restrict_with_exception
  has_many :auth_sessions, dependent: :restrict_with_exception
  has_many :companies, dependent: :destroy

  enum :status, { active: 0, inactive: 1 }

  before_validation :normalize_slug

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  private

  def normalize_slug
    self.slug = slug.to_s.parameterize if slug.present?
  end
end
