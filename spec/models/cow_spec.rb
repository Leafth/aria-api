require 'rails_helper'

RSpec.describe Cow, type: :model do
  let(:tenant) { Tenant.create!(name: "Fazenda", slug: "fazenda-teste") }

  def build_cow(attrs = {})
    Cow.new({
      tenant: tenant,
      name: "Mimosa",
      ear_tag: "001",
      birth_date: Date.new(2023, 1, 1),
      breed: "Nelore",
      weight: 180,
      phase: "calf",
      active: true
    }.merge(attrs))
  end

  it "é válida com dados válidos" do
    cow = build_cow

    expect(cow).to be_valid
  end

  it "inválida sem tenant" do
    cow = build_cow(tenant: nil)

    expect(cow).not_to be_valid
    expect(cow.errors[:tenant]).to be_present
  end

  it "inválida sem nome" do
    cow = build_cow(name: nil)

    expect(cow).not_to be_valid
    expect(cow.errors[:name]).to be_present
  end

  it "inválida sem ear_tag" do
    cow = build_cow(ear_tag: nil)

    expect(cow).not_to be_valid
    expect(cow.errors[:ear_tag]).to be_present
  end

  it "inválida com ear_tag duplicado" do
    Cow.create!(
      tenant: tenant,
      name: "Mimosa",
      ear_tag: "001",
      birth_date: Date.new(2023, 1, 1),
      breed: "Nelore",
      weight: 180,
      phase: "calf",
      active: true
    )

    bull = build_cow(ear_tag: "001")

    expect(bull).not_to be_valid
    expect(bull.errors[:ear_tag]).to be_present
  end

  it "inválida sem data de nascimento" do
    cow = build_cow(birth_date: nil)

    expect(cow).not_to be_valid
    expect(cow.errors[:birth_date]).to be_present
  end

  it "inválida com data de nascimento futura" do
    cow = build_cow(birth_date: 1.day.from_now)
    expect(cow).not_to be_valid
    expect(cow.errors[:birth_date]).to be_present
  end

  it "inválida sem raça" do
    cow = build_cow(breed: nil)

    expect(cow).not_to be_valid
    expect(cow.errors[:breed]).to be_present
  end

  it "inválida sem peso" do
    cow = build_cow(weight: nil)

    expect(cow).not_to be_valid
    expect(cow.errors[:weight]).to be_present
  end

  it "inválida com peso menor ou igual a 0" do
    cow = build_cow(weight: 0)

    expect(cow).not_to be_valid
    expect(cow.errors[:weight]).to be_present
  end

  it "inválida com fase inválida" do
    cow = build_cow(phase: "inválida")

    expect(cow).not_to be_valid
    expect(cow.errors[:phase]).to be_present
  end

  it "é válida com active como false" do
    cow = build_cow(active: false)

    expect(cow).to be_valid
  end
end
