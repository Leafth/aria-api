require 'rails_helper'

RSpec.describe Company, type: :model do
  let(:tenant) { Tenant.create!(name: "Fazenda", slug: "fazenda-teste") }

  def build_company(attrs = {})
    Company.new({
      tenant: tenant,
      name: "Empresa Teste"
    }.merge(attrs))
  end

  it "é válida com dados válidos" do
    company = build_company

    expect(company).to be_valid
  end

  it "inválida sem tenant" do
    company = build_company(tenant: nil)

    expect(company).not_to be_valid
    expect(company.errors[:tenant]).to be_present
  end

  it "inválida sem nome" do
    company = build_company(name: nil)

    expect(company).not_to be_valid
    expect(company.errors[:name]).to be_present
  end
end
