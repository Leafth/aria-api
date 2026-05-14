require "rails_helper"

RSpec.describe Events::HeatDetection do
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
      phase: "calf",
      reproductive_status: "open",
      active: true
    )
  end

  describe "#call" do
    it "cria evento para detecção do cio atual e atualiza status da matriz" do
      occurred_at = Time.current
      params = {
        event_type: "heat_detection",
        occurred_at: occurred_at,
        data: {
          observation: "Cio observado visualmente"
        }
      }

      event = described_class.new(cow: cow, params: params).call

      expect(event).to be_persisted
      expect(event.event_type).to eq("heat_detection")
      expect(cow.reload.reproductive_status).to eq("in_heat")
      expect(cow.reload.last_heat_at).to eq(occurred_at)
    end

    it "cria evento para detecção do cio passado e mantém status da matriz" do
      occurred_at = Time.zone.parse("2026-04-23 10:00:00")
      params = {
        event_type: "heat_detection",
        occurred_at: occurred_at,
        data: {
          observation: "Cio observado visualmente"
        }
      }

      event = described_class.new(cow: cow, params: params).call

      expect(event).to be_persisted
      expect(event.event_type).to eq("heat_detection")
      expect(cow.reload.reproductive_status).to eq("open")
      expect(cow.reload.last_heat_at).to eq(occurred_at)
    end

    it "permite criar cio quando a matriz está em pós-parto" do
      cow.update!(reproductive_status: "postpartum")

      occurred_at = Time.current

      params = {
        occurred_at: occurred_at,
        data: {
          observation: "Primeiro cio após parto"
        }
      }

      event = described_class.new(cow: cow, params: params).call

      expect(event).to be_persisted
      expect(event.event_type).to eq("heat_detection")
      expect(cow.reload.reproductive_status).to eq("in_heat")
      expect(cow..reload.last_heat_at).to eq(occurred_at)
    end

    it "é inválido quando a matriz já está com cio ativo" do
      cow.update!(reproductive_status: "in_heat", last_heat_at: 1.hour.ago)

      params = {
        occurred_at: Time.current,
        data: {
          observation: "Nova tentativa de cio"
        }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.invalid_heat_detection_transition")
      )

      expect(Event.count).to eq(0)
      expect(cow.reload.reproductive_status).to eq("in_heat")
      expect(cow.reload.last_heat_at).to eq(1.hour.ago)
    end

    it "é inválido quando a matriz não está em estado permitido para cio" do
      cow.update!(reproductive_status: "inseminated")

      params = {
        occurred_at: Time.current,
        data: {
          observation: "Animal apresentou sinais de cio"
        }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.invalid_heat_detection_transition")
      )

      expect(Event.count).to eq(0)
      expect(cow.reload.reproductive_status).to eq("inseminated")
      expect(cow.reload.last_heat_at).to be_nil
    end
  end
end
