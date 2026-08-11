require "rails_helper"

RSpec.describe Events::HeatDetection do
  let(:cow) do create(:cow) end

  def call_service(
    occurred_at: Time.current,
    observation: "Cio observado visualmente"
  )
    described_class.new(
      cow: cow,
      params: {
        event_type: "heat_detection",
        occurred_at: occurred_at,
        data: {
          observation: observation
        }
      }
    ).call
  end

  describe "#call" do
    it "cria evento para detecção do cio atual e atualiza status da matriz" do
      occurred_at = 1.hour.ago

      event = call_service(occurred_at: occurred_at)

      expect(event).to be_persisted
      expect(event.event_type).to eq("heat_detection")

      expect(cow.reload.reproductive_status).to eq("in_heat")
      expect(cow.last_heat_at).to be_within(1.second).of(occurred_at)
    end

    it "cria evento para detecção do cio passado e mantém status da matriz" do
      occurred_at = 25.hours.ago

      event = call_service(occurred_at: occurred_at)

      expect(event).to be_persisted
      expect(event.event_type).to eq("heat_detection")

      expect(cow.reload.reproductive_status).to eq("open")
      expect(cow.last_heat_at).to be_within(1.second).of(occurred_at)
    end

    it "permite criar cio quando a matriz está em pós-parto" do
      cow.update!(reproductive_status: "postpartum")

      occurred_at = 1.hour.ago

      event = call_service(occurred_at: occurred_at, observation: "Primeiro cio após parto")

      expect(event).to be_persisted
      expect(event.event_type).to eq("heat_detection")

      expect(cow.reload.reproductive_status).to eq("in_heat")
      expect(cow.last_heat_at).to be_within(1.second).of(occurred_at)
    end

    it "é inválido quando a matriz já está com cio ativo" do
      last_heat_at = 1.hour.ago

      cow.update!(reproductive_status: "in_heat", last_heat_at: last_heat_at)

      expect {
        call_service(observation: "Nova tentativa de cio")
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.invalid_heat_detection_transition")
      )

      expect(Event.count).to eq(0)

      expect(cow.reload.reproductive_status).to eq("in_heat")
      expect(cow.last_heat_at).to be_within(1.second).of(last_heat_at)
    end

    it "é inválido quando a matriz não está em estado permitido para cio" do
      cow.update!(reproductive_status: "inseminated")

      expect {
        call_service(observation: "Animal apresentou sinais de cio")
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.invalid_heat_detection_transition")
      )

      expect(Event.count).to eq(0)

      expect(cow.reload.reproductive_status).to eq("inseminated")
      expect(cow.last_heat_at).to be_nil
    end
  end
end
