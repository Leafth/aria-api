require "rails_helper"

RSpec.describe Events::HeatDetectionWithInsemination do
  let!(:tenant) do
    Tenant.create!(name: "Fazenda", slug: "fazenda-teste", status: :active)
  end

  let!(:bull) do
    tenant.bulls.create!(
      name: "Touro Local",
      breed: "Nelore",
      origin: :local,
      ear_tag: "001"
    )
  end

  let(:cow) do
    tenant.cows.create!(
      name: "Mimosa",
      ear_tag: "001",
      birth_date: "2023-01-01",
      breed: "Nelore",
      weight: 180,
      phase: "calf",
      reproductive_status: "open",
      active: true
    )
  end

  describe "#call" do
    it "cria detecção de cio e inseminação juntos" do
      heat_occurred_at = Time.zone.parse("2026-05-13 08:00:00")
      insemination_occurred_at = Time.zone.parse("2026-05-13 14:00:00")

      params = {
        heat_occurred_at: heat_occurred_at,
        insemination_occurred_at: insemination_occurred_at,
        data: {
          heat_observation: "Animal apresentou sinais de cio",
          method: "natural_mating",
          bull_id: bull.id
        }
      }

      result = described_class.new(cow: cow, params: params).call

      heat_event = result[:heat_detection]
      insemination_event = result[:insemination]

      expect(heat_event).to be_persisted
      expect(heat_event.event_type).to eq("heat_detection")
      expect(heat_event.occurred_at).to eq(heat_occurred_at)

      expect(insemination_event).to be_persisted
      expect(insemination_event.event_type).to eq("insemination")
      expect(insemination_event.occurred_at).to eq(insemination_occurred_at)
      expect(insemination_event.data["method"]).to eq("natural_mating")
      expect(insemination_event.data["bull_id"]).to eq(bull.id)

      cow.reload

      expect(cow.reproductive_status).to eq("inseminated")
      expect(cow.last_heat_at).to eq(heat_occurred_at)
      expect(cow.last_insemination_at).to eq(insemination_occurred_at)
    end

    it "não cria nenhum evento quando cobertura está fora da janela do cio" do
      heat_occurred_at = Time.zone.parse("2026-05-12 08:00:00")
      insemination_occurred_at = Time.zone.parse("2026-05-13 14:00:00")

      params = {
        heat_occurred_at: heat_occurred_at,
        insemination_occurred_at: insemination_occurred_at,
        data: {
          heat_observation: "Animal apresentou sinais de cio",
          method: "natural_mating",
          bull_id: bull.id
        }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(Events::Error, I18n.t!("events.errors.insemination.heat_expired"))

      cow.reload

      expect(cow.reproductive_status).to eq("open")
      expect(cow.last_heat_at).to be_nil
      expect(cow.last_insemination_at).to be_nil
    end
  end
end
