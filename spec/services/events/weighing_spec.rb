require "rails_helper"

RSpec.describe Events::Weighing do
  let!(:tenant) do
    Tenant.create!(name: "Fazenda", slug: "fazenda-teste", status: :active)
  end

  let(:breed) { Breed.create!(tenant: tenant, name: "Nelore") }

  let(:cow) do
    tenant.cows.create!(
      name: "Mimosa",
      ear_tag: "001",
      birth_date: "2023-01-01",
      breed: breed,
      weight: 180,
      phase: "calf",
      active: true
    )
  end

  describe "#call" do
    it "cria evento de pesagem" do
      occurred_at = Time.zone.parse("2026-05-05")

      params = {
        event_type: "weighing",
        occurred_at: "2026-05-05",
        data: { weight: 200 }
      }

      event = described_class.new(cow: cow, params: params).call

      expect(event).to be_persisted
      expect(event.event_type).to eq("weighing")
      expect(event.data["weight"]).to eq(200)
      expect(cow.reload.weight).to eq(200)
      expect(cow.reload.last_weighing_at).to eq(occurred_at)
    end

    it "é inválido sem peso" do
      params = {
        event_type: "weighing",
        occurred_at: "2026-05-05",
        data: {}
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(Events::Error)
    end

    it "é inválido com peso negativo" do
      params = {
        event_type: "weighing",
        occurred_at: "2026-05-05",
        data: { weight: -200 }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(Events::Error)
    end

    it "mantém o peso da pesagem mais recente" do
      recent_occurred_at = Time.zone.parse("2026-05-05")
      old_occurred_at = Time.zone.parse("2026-01-01")

      params_one = {
        event_type: "weighing",
        occurred_at: recent_occurred_at,
        data: { weight: 200 }
      }

      params_two = {
        event_type: "weighing",
        occurred_at: old_occurred_at,
        data: { weight: 190 }
      }

      described_class.new(cow: cow, params: params_one).call
      described_class.new(cow: cow, params: params_two).call

      expect(cow.reload.weight).to eq(200)
      expect(cow.last_weighing_at).to eq(recent_occurred_at)
    end

    it "é inválido se a cow estiver inativa" do
      cow.update!(active: false)

      params = {
        event_type: "weighing",
        occurred_at: "2026-05-05",
        data: { weight: 200 }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(Events::Error)

      expect(cow.reload.weight).to eq(180)
    end
  end
end
