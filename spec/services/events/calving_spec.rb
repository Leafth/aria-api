require "rails_helper"

RSpec.describe Events::Calving do
  let!(:tenant) do
    Tenant.create!(name: "Fazenda", slug: "fazenda-teste", status: :active)
  end

  let(:cow) do
    tenant.cows.create!(
      name: "Mimosa",
      ear_tag: "001",
      birth_date: "2023-01-01",
      breed: "Nelore",
      weight: 180,
      phase: "young",
      reproductive_status: "pregnant",
      last_heat_at: 286.days.ago,
      last_insemination_at: 285.days.ago,
      pregnancy_confirmed_at: 280.days.ago,
      active: true
    )
  end

  let(:occurred_at) { Time.current.change(usec: 0) }

  describe "#call" do
    it "cria evento para parto e atualiza status da matriz" do
      params = {
        event_type: "calving",
        occurred_at: occurred_at,
        data: {
          observation: "Parto sem complicações"
        }
      }

      event = described_class.new(cow: cow, params: params).call

      expect(event).to be_persisted
      expect(event.event_type).to eq("calving")
      expect(cow.reload.reproductive_status).to eq("postpartum")
      expect(cow.reload.last_calving_at).to be_within(1.second).of(occurred_at)
    end

    it "é inválido quando a matriz não está prenha" do
      cow.update!(reproductive_status: "inseminated", pregnancy_confirmed_at: nil)

      params = {
        occurred_at: occurred_at,
        data: {
          observation: "Parto sem complicações"
        }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.invalid_calving_transition")
      )

      expect(Event.count).to eq(0)
      expect(cow.reload.reproductive_status).to eq("inseminated")
      expect(cow.reload.last_calving_at).to be_nil
    end
  end
end
