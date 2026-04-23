class Bull < ApplicationRecord
  belongs_to :tenant
  belongs_to :company, optional: true

  enum :origin, {
    local: "local",
    company: "company"
  }

  validates :name, presence: true
  validates :breed, presence: true
  validates :origin, presence: true

  validates :ear_tag, uniqueness: { scope: :tenant_id }, allow_nil: true

  validates :origin_rules

  private

  def origin_rules
    if local?
      errors.add(:company, "Touros locais não devem estar associados a uma empresa") if company_id.present?
    end

    if company?
      errors.add(:company, "Touros de empresa devem obrigatoriamente estar associados") if company_id.blank?
      errors.add(:ear_tag, "Não deve existir para touros de empresa") if ear_tag.present?
    end
  end
end
