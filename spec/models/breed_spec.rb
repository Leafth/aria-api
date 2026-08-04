require "rails_helper"

RSpec.describe Breed, type: :model do
  it "é válida com dados válidos" do
    breed = build(:breed)

    expect(breed).to be_valid
  end

  it "inválida sem tenant" do
    breed = build(:breed, tenant: nil)

    expect(breed).not_to be_valid
    expect(breed.errors[:tenant]).to be_present
  end

  it "inválida sem nome" do
    breed = build(:breed, name: nil)

    expect(breed).not_to be_valid
    expect(breed.errors[:name]).to be_present
  end

  it "remove espaços do nome" do
    breed = build(:breed, name: "  Nelore  ")

    breed.valid?

    expect(breed.name).to eq("Nelore")
  end

  it "preenche o nome normalizado a partir do nome" do
    breed = build(:breed, name: "Nelore")

    breed.valid?

    expect(breed.normalized_name).to eq("nelore")
  end

  it "normaliza acentos e espaços no nome normalizado" do
    breed = build(:breed, name: " tabapuã leiteiro ")

    breed.valid?

    expect(breed.name).to eq("Tabapuã Leiteiro")
    expect(breed.normalized_name).to eq("tabapua-leiteiro")
  end

  it "inválida com nome normalizado duplicado no mesmo tenant" do
    existing_breed = create(:breed, name: "Nelore")

    duplicate_breed = build(
      :breed,
      tenant: existing_breed.tenant,
      name: " nelore "
    )
    expect(duplicate_breed).not_to be_valid
    expect(duplicate_breed.errors[:normalized_name]).to be_present
  end
end
