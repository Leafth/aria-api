require 'rails_helper'

RSpec.describe Bull, type: :model do
  it "é válido com dados válidos para touro local" do
    bull = build(:bull)

    expect(bull).to be_valid
  end

  it "é válido com dados válidos para touro de empresa" do
    bull = build(:bull, :from_company)

    expect(bull).to be_valid
  end

  it "inválido sem tenant" do
    bull = build(:bull, tenant: nil)

    expect(bull).not_to be_valid
    expect(bull.errors[:tenant]).to be_present
  end

  it "inválido sem nome" do
    bull = build(:bull, name: nil)

    expect(bull).not_to be_valid
    expect(bull.errors[:name]).to be_present
  end

  it "inválido sem raça" do
    bull = build(:bull, breed: nil)

    expect(bull).not_to be_valid
    expect(bull.errors[:breed]).to be_present
  end

  it "inválido com origem inválida" do
    bull = build(:bull, origin: "inválida")

    expect(bull).not_to be_valid
    expect(bull.errors[:origin]).to be_present
  end

  it "inválido com ear_tag duplicado" do
    existing_bull = create(:bull, ear_tag: "001")

    duplicate_bull = build(
      :bull,
      tenant: existing_bull.tenant,
      ear_tag: existing_bull.ear_tag
    )

    expect(duplicate_bull).not_to be_valid
    expect(duplicate_bull.errors[:ear_tag]).to be_present
  end

  it "inválido se touro local com empresa" do
    bull = build(:bull, company: create(:company))

    expect(bull).not_to be_valid
    expect(bull.errors[:company]).to be_present
  end

  it "inválido se touro de empresa sem empresa" do
    bull = build(:bull, origin: :company, company: nil, ear_tag: nil)

    expect(bull).not_to be_valid
    expect(bull.errors[:company]).to be_present
  end

  it "inválido se touro de empresa com ear_tag" do
    bull = build(:bull, :from_company, ear_tag: "001")

    expect(bull).not_to be_valid
    expect(bull.errors[:ear_tag]).to be_present
  end
end
