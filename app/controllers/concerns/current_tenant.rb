module CurrentTenant
  extend ActiveSupport::Concern

  included do
    before_action :set_current_tenant
  end

  private

  def set_current_tenant
    @current_tenant = resolve_current_tenant
  end

  def current_tenant
    @current_tenant
  end

  def resolve_current_tenant
    slug = request.headers["X-Tenant-Slug"].to_s.strip.downcase
    raise ActiveRecord::RecordNotFound, "Tenant não informado" if slug.blank?

    tenant = Tenant.find_by!(slug: slug)
    raise ActiveRecord::RecordNotFound, "Tenant inativo" unless tenant.active?

    tenant
  end
end
