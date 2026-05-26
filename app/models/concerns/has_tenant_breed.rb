module HasTenantBreed
  extend ActiveSupport::Concern

  included do
    belongs_to :breed

    validate :breed_belongs_to_same_tenant
  end

  private

  def breed_belongs_to_same_tenant
    return if breed.blank? || tenant.blank?

    errors.add(:breed, :invalid) if breed.tenant_id != tenant_id
  end
end
