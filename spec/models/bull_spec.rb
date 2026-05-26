require 'rails_helper'

RSpec.describe Bull, type: :model do
  let(:tenant) { Tenant.create!(name: "Fazenda", slug: "fazenda-teste") }
  let(:company) { Company.create!(tenant: tenant, name: "Empresa Teste") }
  let(:breed) { Breed.create!(tenant: tenant, name: "Nelore") }

  def build_bull(attrs = {})
    Bull.new({
      tenant: tenant,
      name: "Touro 1",
      breed: breed,
      origin: :local,
      ear_tag: "001",
      company: nil
    }.merge(attrs))
  end

  it "é válido com dados válidos para touro local" do
    bull = build_bull

    expect(bull).to be_valid
  end

  it "é válido com dados válidos para touro de empresa" do
    bull = build_bull(
      origin: :company,
      company: company,
      ear_tag: nil
    )

    expect(bull).to be_valid
  end

  it "inválido sem tenant" do
    bull = build_bull(tenant: nil)

    expect(bull).not_to be_valid
    expect(bull.errors[:tenant]).to be_present
  end

  it "inválido sem nome" do
    bull = build_bull(name: nil)

    expect(bull).not_to be_valid
    expect(bull.errors[:name]).to be_present
  end

  it "inválido sem raça" do
    bull = build_bull(breed: nil)

    expect(bull).not_to be_valid
    expect(bull.errors[:breed]).to be_present
  end

  it "inválido com origem inválida" do
    bull = build_bull(origin: "inválida")

    expect(bull).not_to be_valid
    expect(bull.errors[:origin]).to be_present
  end

  it "inválido com ear_tag duplicado" do
    Bull.create!(
      tenant: tenant,
      name: "Touro 2",
      breed: breed,
      origin: :local,
      ear_tag: "001",
    )

    bull = build_bull(ear_tag: "001")

    expect(bull).not_to be_valid
    expect(bull.errors[:ear_tag]).to be_present
  end

  it "inválido se touro local com empresa" do
    bull = build_bull(company: company)

    expect(bull).not_to be_valid
    expect(bull.errors[:company]).to be_present
  end

  it "inválido se touro de empresa sem empresa" do
    bull = build_bull(origin: :company, company: nil, ear_tag: nil)

    expect(bull).not_to be_valid
    expect(bull.errors[:company]).to be_present
  end

  it "inválido se touro de empresa com ear_tag" do
    bull = build_bull(origin: :company, company: company, ear_tag: "001")

    expect(bull).not_to be_valid
    expect(bull.errors[:ear_tag]).to be_present
  end
end
