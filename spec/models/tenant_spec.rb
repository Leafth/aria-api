require 'rails_helper'

RSpec.describe Tenant, type: :model do
  def build_tenant(attrs = {})
    Tenant.new({
      name: "Fazenda Feliz",
      slug: "fazenda-feliz",
      status: :active
    }.merge(attrs))
  end

  it "é válido com dados válidos" do
    expect(build_tenant).to be_valid
  end

  it "inválido sem nome" do
    tenant = build_tenant(name: nil)

    expect(tenant).not_to be_valid
    expect(tenant.errors[:name]).to be_present
  end

  it "inválido sem slug" do
    tenant = build_tenant(slug: nil)

    expect(tenant).not_to be_valid
    expect(tenant.errors[:slug]).to be_present
  end

  it "inválido com slug já existente" do
    Tenant.create!(
      name: "Fazenda Feliz Demais",
      slug: "fazenda-feliz",
      status: :active
    )

    tenant = build_tenant()

    expect(tenant).not_to be_valid
    expect(tenant.errors[:slug]).to be_present
  end

  it "normaliza slug antes da validação" do
    tenant = build_tenant(slug: " Fazenda São João ")

    tenant.valid?

    expect(tenant.slug).to eq("fazenda-sao-joao")
  end
end
