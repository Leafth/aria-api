module CurrentTenant
  extend ActiveSupport::Concern

  private

  def current_tenant
    @current_tenant ||= resolve_current_tenant
  end

  def resolve_current_tenant
    slug = request.headers["X-Tenant-Slug"].to_s.strip.downcase
    return nil if slug.blank?

    Tenant.find_by!(slug: slug)
  end
end
