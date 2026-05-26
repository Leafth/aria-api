# spec/services/cow_events/deactivation_spec.rb
require "rails_helper"

RSpec.describe Events::Inactivation do
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
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "é inválido com reason inválido" do
      params = {
        event_type: "inactivation",
        data: { reason: "outro" }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
