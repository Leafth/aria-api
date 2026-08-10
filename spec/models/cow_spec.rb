require 'rails_helper'

RSpec.describe Cow, type: :model do
  it "é válida com dados válidos" do
    cow = build(:cow)

    expect(cow).to be_valid
  end

  it "inválida sem tenant" do
    cow = build(:cow, tenant: nil)

    expect(cow).not_to be_valid
    expect(cow.errors[:tenant]).to be_present
  end

  it "inválida sem nome" do
    cow = build(:cow, name: nil)

    expect(cow).not_to be_valid
    expect(cow.errors[:name]).to be_present
  end

  it "inválida sem ear_tag" do
    cow = build(:cow, ear_tag: nil)

    expect(cow).not_to be_valid
    expect(cow.errors[:ear_tag]).to be_present
  end

  it "inválida com ear_tag duplicado" do
    existing_cow = create(:cow, ear_tag: "001")

    duplicate_cow = build(
      :cow,
      tenant: existing_cow.tenant,
      ear_tag: existing_cow.ear_tag
    )

    expect(duplicate_cow).not_to be_valid
    expect(duplicate_cow.errors[:ear_tag]).to be_present
  end

  it "inválida sem data de nascimento" do
    cow = build(:cow, birth_date: nil)

    expect(cow).not_to be_valid
    expect(cow.errors[:birth_date]).to be_present
  end

  it "inválida com data de nascimento futura" do
    cow = build(:cow, birth_date: 1.day.from_now)

    expect(cow).not_to be_valid
    expect(cow.errors[:birth_date]).to be_present
  end

  it "inválida sem raça" do
    cow = build(:cow, breed: nil)

    expect(cow).not_to be_valid
    expect(cow.errors[:breed]).to be_present
  end

  it "inválida sem peso" do
    cow = build(:cow, weight: nil)

    expect(cow).not_to be_valid
    expect(cow.errors[:weight]).to be_present
  end

  it "inválida com peso menor ou igual a 0" do
    cow = build(:cow, weight: 0)

    expect(cow).not_to be_valid
    expect(cow.errors[:weight]).to be_present
  end

  it "inválida com fase inválida" do
    cow = build(:cow, phase: nil)

    expect(cow).not_to be_valid
    expect(cow.errors[:phase]).to be_present
  end

  it "é válida com active como false" do
    cow = build(:cow, :inactive)

    expect(cow).to be_valid
  end
end
