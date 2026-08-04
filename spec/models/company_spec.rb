require 'rails_helper'

RSpec.describe Company, type: :model do
  it "é válida com dados válidos" do
    company = build(:company)

    expect(company).to be_valid
  end

  it "inválida sem tenant" do
    company = build(:company, tenant: nil)

    expect(company).not_to be_valid
    expect(company.errors[:tenant]).to be_present
  end

  it "inválida sem nome" do
    company = build(:company, name: nil)

    expect(company).not_to be_valid
    expect(company.errors[:name]).to be_present
  end
end
