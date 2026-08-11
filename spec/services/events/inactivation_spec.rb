# spec/services/cow_events/deactivation_spec.rb
require "rails_helper"

RSpec.describe Events::Inactivation do
  let(:cow) { create(:cow) }

  def call_service(reason:)
    described_class.new(
      cow: cow,
      params: {
        event_type: "inactivation",
        data: reason.nil? ? {} : { reason: reason }
      }
    ).call
  end

  describe "#call" do
    it "cria evento com reason e inativa cow" do
      event = call_service(reason: "sale")

      expect(event).to be_persisted
      expect(event.event_type).to eq("inactivation")
      expect(cow.reload.active).to eq(false)
      expect(event.data["reason"]).to eq("sale")
    end

    it "é inválido sem reason" do
      expect {
        call_service(reason: nil)
      }.to raise_error(Events::Error)
    end

    it "é inválido com reason inválido" do
      expect {
        call_service(reason: "outro")
      }.to raise_error(Events::Error)
    end
  end
end
