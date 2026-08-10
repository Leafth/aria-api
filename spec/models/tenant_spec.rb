require 'rails_helper'

RSpec.describe Tenant, type: :model do
  it "é válido com dados válidos" do
    expect(build(:tenant)).to be_valid
  end

  it "inválido sem nome" do
    tenant = build(:tenant, name: nil)

    expect(tenant).not_to be_valid
    expect(tenant.errors[:name]).to be_present
  end

  it "inválido sem slug" do
    tenant = build(:tenant, slug: nil)

    expect(tenant).not_to be_valid
    expect(tenant.errors[:slug]).to be_present
  end

  it "inválido com slug já existente" do
    existing_tenant = create(:tenant)

    duplicate_tenant = build(:tenant, slug: existing_tenant.slug)

    expect(duplicate_tenant).not_to be_valid
    expect(duplicate_tenant.errors[:slug]).to be_present
  end

  it "normaliza slug antes da validação" do
    tenant = build(:tenant, slug: " Fazenda São João ")

    tenant.valid?

    expect(tenant.slug).to eq("fazenda-sao-joao")
  end
end
