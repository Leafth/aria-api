require "rails_helper"

RSpec.describe Events::HeatDetectionWithInsemination do
  let(:tenant) { create(:tenant) }
  let(:cow) do create(:cow, tenant: tenant) end
  let(:bull) do create(:bull, tenant: tenant) end

  def call_service(
    heat_occurred_at:,
    insemination_occurred_at:
  )
    described_class.new(
      cow: cow,
      params: {
        heat_occurred_at: heat_occurred_at,
        insemination_occurred_at: insemination_occurred_at,
        data: {
          heat_observation: "Animal apresentou sinais de cio",
          method: "natural_mating",
          bull_id: bull.id
        }
      }
    ).call
  end

  describe "#call" do
    it "cria detecção de cio e inseminação juntos" do
      heat_occurred_at = 6.hours.ago.change(usec: 0)
      insemination_occurred_at = 1.hour.ago.change(usec: 0)

      result = call_service(
        heat_occurred_at: heat_occurred_at,
        insemination_occurred_at: insemination_occurred_at
      )

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

      expect(cow.reload.reproductive_status).to eq("inseminated")
      expect(cow.last_heat_at).to eq(heat_occurred_at)
      expect(cow.last_insemination_at).to eq(insemination_occurred_at)
    end

    it "não cria nenhum evento quando cobertura está fora da janela do cio" do
      heat_occurred_at = 30.hours.ago.change(usec: 0)
      insemination_occurred_at = 1.hour.ago.change(usec: 0)

      expect {
        call_service(
          heat_occurred_at: heat_occurred_at,
          insemination_occurred_at: insemination_occurred_at
        )
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.insemination.heat_expired")
      )

      expect(cow.reload.reproductive_status).to eq("open")
      expect(cow.last_heat_at).to be_nil
      expect(cow.last_insemination_at).to be_nil
    end
  end
end
