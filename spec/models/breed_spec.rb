require "rails_helper"

RSpec.describe Breed, type: :model do
  let(:tenant) { Tenant.create!(name: "Fazenda", slug: "fazenda-teste") }

  def build_breed(attrs = {})
    Breed.new({
      tenant: tenant,
      name: "Nelore"
    }.merge(attrs))
  end

  it "é válida com dados válidos" do
    breed = build_breed

    expect(breed).to be_valid
  end

  it "inválida sem tenant" do
    breed = build_breed(tenant: nil)

    expect(breed).not_to be_valid
    expect(breed.errors[:tenant]).to be_present
  end

  it "inválida sem nome" do
    breed = build_breed(name: nil)

    expect(breed).not_to be_valid
    expect(breed.errors[:name]).to be_present
  end

  it "remove espaços do nome" do
    breed = build_breed(name: "  Nelore  ")

    breed.valid?

    expect(breed.name).to eq("Nelore")
  end

  it "preenche o nome normalizado a partir do nome" do
    breed = build_breed(name: "Nelore")

    breed.valid?

    expect(breed.normalized_name).to eq("nelore")
  end

  it "normaliza acentos e espaços no nome normalizado" do
    breed = build_breed(name: " Tabapuã Leiteiro ")

    breed.valid?

    expect(breed.name).to eq("Tabapuã Leiteiro")
    expect(breed.normalized_name).to eq("tabapua-leiteiro")
  end

  it "inválida com nome normalizado duplicado no mesmo tenant" do
    Breed.create!(tenant: tenant, name: "Nelore")

    breed = build_breed(name: " nelore ")

    expect(breed).not_to be_valid
    expect(breed.errors[:normalized_name]).to be_present
  end
end
