require "rails_helper"

RSpec.describe Events::Weighing do
  let(:cow) { create(:cow, weight: 180) }
  let(:occurred_at) { 1.day.ago.change(usec: 0) }

  describe "#call" do
    it "cria evento de pesagem" do
      params = {
        event_type: "weighing",
        occurred_at: occurred_at,
        data: { weight: 200 }
      }

      event = described_class.new(cow: cow, params: params).call

      expect(event).to be_persisted
      expect(event.event_type).to eq("weighing")
      expect(event.data["weight"]).to eq(200)

      cow.reload

      expect(cow.weight).to eq(200)
      expect(cow.last_weighing_at).to eq(occurred_at)
    end

    it "é inválido sem peso" do
      params = {
        event_type: "weighing",
        occurred_at: occurred_at,
        data: {}
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(Events::Error)
    end

    it "é inválido com peso negativo" do
      params = {
        event_type: "weighing",
        occurred_at: occurred_at,
        data: { weight: -200 }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(Events::Error)
    end

    it "mantém o peso da pesagem mais recente" do
      recent_occurred_at = 1.day.ago.change(usec: 0)
      old_occurred_at = 2.days.ago.change(usec: 0)

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

      cow.reload

      expect(cow.weight).to eq(200)
      expect(cow.last_weighing_at).to eq(recent_occurred_at)
    end

    it "é inválido se a cow estiver inativa" do
      cow.update!(active: false)

      params = {
        event_type: "weighing",
        occurred_at: occurred_at,
        data: { weight: 200 }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(Events::Error)

      expect(cow.reload.weight).to eq(180)
    end
  end
end
