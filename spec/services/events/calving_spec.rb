require "rails_helper"

RSpec.describe Events::Calving do
  let(:occurred_at) { Time.current.change(usec: 0) }

  let(:cow) do
    create(
      :cow,
      :young,
      :pregnant,
      last_heat_at: 286.days.ago.change(usec: 0),
      last_insemination_at: 285.days.ago.change(usec: 0),
      pregnancy_confirmed_at: pregnancy_confirmed_at
    )
  end

  let(:pregnancy_confirmed_at) { 280.days.ago.change(usec: 0) }

  describe "#call" do
    it "cria evento para parto, atualiza status da matriz, e muda fase para primípara" do
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

      cow.reload

      expect(cow.reproductive_status).to eq("postpartum")
      expect(cow.phase).to eq("primiparous")
      expect(cow.last_calving_at).to be_within(1.second).of(occurred_at)
    end

    it "cria evento para parto, atualiza status da matriz, e muda fase de primípara para multípara" do
      cow.update!(phase: "primiparous")

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

      cow.reload

      expect(cow.reproductive_status).to eq("postpartum")
      expect(cow.phase).to eq("multiparous")
      expect(cow.last_calving_at).to be_within(1.second).of(occurred_at)
    end

    it "cria evento para parto, atualiza status da matriz, e mantém fase quando multípara" do
      cow.update!(phase: "multiparous")

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

      cow.reload

      expect(cow.reproductive_status).to eq("postpartum")
      expect(cow.phase).to eq("multiparous")
      expect(cow.last_calving_at).to be_within(1.second).of(occurred_at)
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

      cow.reload

      expect(cow.reproductive_status).to eq("inseminated")
      expect(cow.last_calving_at).to be_nil
    end
  end
end
