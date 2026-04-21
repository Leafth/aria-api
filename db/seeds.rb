tenant = Tenant.find_or_create_by!(slug: "fazenda-teste") do |t|
  t.name = "Fazenda teste"
  t.status = :active
end

User.find_or_create_by!(tenant: tenant, email: "admin@fazenda.com") do |user|
  user.name = "Administrador"
  user.password = "@admin123"
  user.password_confirmation = "@admin123"
  user.status = :active
end
