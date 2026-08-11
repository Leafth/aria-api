require "rails_helper"

RSpec.describe Cows::Insights::InactiveStatus do
  let(:cow) { create(:cow, :young, reproductive_status: :open) }

  def call_service
    described_class.new(cow: cow).call
  end

  describe "#call" do
    it "retorna a data e o motivo da inativação" do
      occurred_at = 1.day.ago.change(usec: 0)

      Events::Inactivation.new(
        cow: cow,
        params: {
          occurred_at: occurred_at,
          data: { reason: "sale" }
        }
      ).call

      result = call_service

      expect(result).to eq(
        inactivated_at: I18n.l(occurred_at.to_date),
        inactivated_reason: "sale"
      )
    end

    it "retorna nil quando não existe evento de inativação" do
      result = call_service

      expect(result).to eq(
        inactivated_at: nil,
        inactivated_reason: nil
      )
    end
  end
end
