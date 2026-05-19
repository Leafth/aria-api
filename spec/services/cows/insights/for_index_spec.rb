require "rails_helper"

RSpec.describe Cows::Insights::ForIndex do
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
      reproductive_status: reproductive_status,
      last_heat_at: last_heat_at,
      last_insemination_at: last_insemination_at,
      pregnancy_confirmed_at: pregnancy_confirmed_at,
      last_calving_at: last_calving_at,
      active: true
    )
  end

  let(:reproductive_status) { "open" }
  let(:last_heat_at) { nil }
  let(:last_insemination_at) { nil }
  let(:pregnancy_confirmed_at) { nil }
  let(:last_calving_at) { nil }

  let(:reproductive_status_insight) do
    {
      status: reproductive_status,
      message: "Mensagem do status",
      observation: observation,
      alerts: reproductive_alerts
    }
  end

  let(:observation) { "Observação do status" }
  let(:reproductive_alerts) { [] }

  before do
    allow(Cows::Insights::ReproductiveStatus)
      .to receive(:new)
      .with(cow: cow)
      .and_return(instance_double(Cows::Insights::ReproductiveStatus, call: reproductive_status_insight))
  end

  describe "#call" do
    it "retorna status e alerts para o index" do
      result = described_class.new(cow: cow).call

      expect(result).to eq(
        status: {
          code: "open",
          message: I18n.t!("cows.insights.index.status.open"),
          occurred_at: nil
        },
        alerts: [
          {
            level: "info",
            code: "open",
            message: "Observação do status"
          }
        ]
      )
    end

    context "quando o status é open" do
      let(:reproductive_status) { "open" }
      let(:last_calving_at) { Time.zone.parse("2026-05-01 10:00:00") }

      it "usa a data do último parto como occurred_at" do
        result = described_class.new(cow: cow).call

        expect(result[:status]).to eq(
          code: "open",
          message: I18n.t!("cows.insights.index.status.open"),
          occurred_at: I18n.l(last_calving_at.to_date)
        )
      end
    end

    context "quando o status é in_heat" do
      let(:reproductive_status) { "in_heat" }
      let(:last_heat_at) { Time.zone.parse("2026-05-18 10:00:00") }

      it "usa a data do último cio como occurred_at" do
        result = described_class.new(cow: cow).call

        expect(result[:status]).to eq(
          code: "in_heat",
          message: I18n.t!("cows.insights.index.status.in_heat"),
          occurred_at: I18n.l(last_heat_at.to_date)
        )
      end
    end

    context "quando o status é inseminated" do
      let(:reproductive_status) { "inseminated" }
      let(:last_insemination_at) { Time.zone.parse("2026-05-18 10:00:00") }

      it "usa a data da última inseminação como occurred_at" do
        result = described_class.new(cow: cow).call

        expect(result[:status]).to eq(
          code: "inseminated",
          message: I18n.t!("cows.insights.index.status.inseminated"),
          occurred_at: I18n.l(last_insemination_at.to_date)
        )
      end
    end

    context "quando o status é pregnant" do
      let(:reproductive_status) { "pregnant" }
      let(:pregnancy_confirmed_at) { Time.zone.parse("2026-05-18 10:00:00") }

      it "usa a data da confirmação de prenhez como occurred_at" do
        result = described_class.new(cow: cow).call

        expect(result[:status]).to eq(
          code: "pregnant",
          message: I18n.t!("cows.insights.index.status.pregnant"),
          occurred_at: I18n.l(pregnancy_confirmed_at.to_date)
        )
      end
    end

    context "quando o status é postpartum" do
      let(:reproductive_status) { "postpartum" }
      let(:last_calving_at) { Time.zone.parse("2026-05-18 10:00:00") }

      it "usa a data do último parto como occurred_at" do
        result = described_class.new(cow: cow).call

        expect(result[:status]).to eq(
          code: "postpartum",
          message: I18n.t!("cows.insights.index.status.postpartum"),
          occurred_at: I18n.l(last_calving_at.to_date)
        )
      end
    end
  end
end
