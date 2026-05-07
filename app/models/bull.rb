class Bull < ApplicationRecord
  belongs_to :tenant
  belongs_to :company, optional: true

  enum :origin, {
    local: "local",
    company: "company"
  }, validate: { message: :invalid_origin }

  validates :name, presence: true
  validates :breed, presence: true
  validates :origin, presence: true

  validates :ear_tag, uniqueness: { scope: :tenant_id }, allow_nil: true

  validate :origin_rules

  private

  def origin_rules
    if local?
      errors.add(:company, :local_with_company) if company_id.present?
    end

    if company?
      errors.add(:company, :company_required) if company_id.blank?
      errors.add(:ear_tag, :company_with_ear_tag) if ear_tag.present?
    end
  end
end
