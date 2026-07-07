class Bull < ApplicationRecord
  belongs_to :tenant
  belongs_to :company, optional: true

  include HasTenantBreed

  before_validation :normalize_ear_tag

  enum :origin, {
    local: "local",
    company: "company"
  }, validate: { message: :invalid_origin }

  validates :name, presence: true
  validates :origin, presence: true

  validates :ear_tag,
            presence: true,
            uniqueness: { scope: :tenant_id },
            format: {
              with: /\A\d{3}\z/,
              message: :invalid_ear_tag_format
            }

  validate :origin_rules

  private

  def origin_rules
    if local?
      errors.add(:ear_tag, :local_without_ear_tag) if ear_tag.blank?
      errors.add(:company, :local_with_company) if company_id.present?
    end

    if company?
      errors.add(:company, :company_required) if company_id.blank?
      errors.add(:ear_tag, :company_with_ear_tag) if ear_tag.present?
    end
  end

  def normalize_ear_tag
    return if ear_tag.blank?

    self.ear_tag = ear_tag.to_s.gsub(/\D/, "").rjust(3, "0")
  end
end
