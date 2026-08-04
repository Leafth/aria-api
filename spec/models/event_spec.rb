require 'rails_helper'

RSpec.describe Event, type: :model do
  it "é válido com dados válidos" do
    event = build(:event)

    expect(event).to be_valid
  end

  it "inválido sem type válido" do
    event = build(:event, event_type: "outro")

    expect(event).not_to be_valid
  end

  it "inválido com data futura" do
    event = build(:event, occurred_at: 1.day.from_now)

    expect(event).not_to be_valid
    expect(event.errors[:occurred_at]).to include(I18n.t!("activerecord.errors.models.event.attributes.occurred_at.future_date"))
  end

  it "é inválido com data anterior à data de nascimento da matriz" do
    cow = build(:cow)

    event = build(
      :event,
      cow: cow,
      tenant: cow.tenant,
      occurred_at: cow.birth_date - 1.day
    )

    expect(event).not_to be_valid
    expect(event.errors[:occurred_at]).to include(I18n.t!("activerecord.errors.models.event.attributes.occurred_at.before_birth_date"))
  end
end
