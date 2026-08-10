# spec/services/cow_events/deactivation_spec.rb
require "rails_helper"

RSpec.describe Events::Inactivation do
  let(:cow) { create(:cow) }

  describe "#call" do
    it "cria evento com reason e inativa cow" do
      params = {
        event_type: "inactivation",
        data: { reason: "sale" }
      }

      event = described_class.new(cow: cow, params: params).call

      expect(event).to be_persisted
      expect(event.event_type).to eq("inactivation")
      expect(cow.reload.active).to eq(false)
      expect(event.data["reason"]).to eq("sale")
    end

    it "é inválido sem reason" do
      params = {
        event_type: "inactivation",
        data: {}
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(Events::Error)
    end

    it "é inválido com reason inválido" do
      params = {
        event_type: "inactivation",
        data: { reason: "outro" }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(Events::Error)
    end
  end
end
