require 'rails_helper'

RSpec.describe Event, type: :model do
  let!(:tenant) do
    Tenant.create!(name: "Fazenda", slug: "fazenda-teste", status: :active)
  end

  let!(:cow) do
    tenant.cows.create!(
      name: "Mimosa",
      ear_tag: "001",
      birth_date: "2023-01-01",
      breed: "Nelore",
      weight: 180,
      phase: "calf",
      active: true
    )
  end

  it "é válido com dados válidos" do
    event = Event.new(
      cow: cow,
      tenant: tenant,
      event_type: "inactivation",
      occurred_at: Time.current,
    )

    expect(event).to be_valid
  end

  it "inválido sem type válido" do
    event = Event.new(
      cow: cow,
      tenant: tenant,
      event_type: "outro",
      occurred_at: Time.current
    )

    expect(event).not_to be_valid
  end

  it "inválido com data futura" do
    event = Event.new(
      cow: cow,
      tenant: tenant,
      event_type: "inactivation",
      occurred_at: 1.day.from_now
    )

    expect(event).not_to be_valid
    expect(event.errors[:occurred_at]).to include(I18n.t!("activerecord.errors.models.event.attributes.occurred_at.future_date"))
  end

  it "é inválido com data anterior à data de nascimento da matriz" do
    event = Event.new(
      cow: cow,
      tenant: tenant,
      event_type: "inactivation",
      occurred_at: cow.birth_date - 1.day
    )

    expect(event).not_to be_valid
    expect(event.errors[:occurred_at]).to include(I18n.t!("activerecord.errors.models.event.attributes.occurred_at.before_birth_date"))
  end
end
