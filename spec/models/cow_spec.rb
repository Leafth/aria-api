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
    expect(build_cow).to be_valid
  end
end
