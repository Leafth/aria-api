require "rails_helper"

RSpec.describe Cows::Insights::InactiveStatus do
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
      phase: "young",
      reproductive_status: "open",
      active: true
    )
  end

  describe "#call" do
    it "retorna a data e o motivo da inativação" do
      occurred_at = Time.zone.parse("2026-05-18 10:00:00")

      Events::Inactivation.new(
        cow: cow,
        params: {
          occurred_at: occurred_at,
          data: { reason: "sale" }
        }
      ).call

      result = described_class.new(cow: cow).call

      expect(result).to eq(
        inactivated_at: I18n.l(occurred_at.to_date),
        inactivated_reason: "sale"
      )
    end

    it "retorna nil quando não existe evento de inativação" do
      result = described_class.new(cow: cow).call

      expect(result).to eq(
        inactivated_at: nil,
        inactivated_reason: nil
      )
    end
  end
end
