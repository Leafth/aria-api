require "rails_helper"

RSpec.describe Cows::Insights::ForIndex do
  let(:cow) do
    create(
      :cow,
      :young,
      reproductive_status: reproductive_status,
      last_heat_at: last_heat_at,
      last_insemination_at: last_insemination_at,
      pregnancy_confirmed_at: pregnancy_confirmed_at,
      last_calving_at: last_calving_at,
      last_weighing_at: last_weighing_at
    )
  end

  let(:reproductive_status) { :open }
  let(:occurred_at) { 1.day.ago.change(usec: 0) }

  let(:last_weighing_at) { occurred_at }
  let(:last_heat_at) { occurred_at }
  let(:last_insemination_at) { nil }
  let(:pregnancy_confirmed_at) { nil }
  let(:last_calving_at) { nil }

  let(:reproductive_status_insight) do
    {
      status: reproductive_status.to_s,
      message: "Mensagem do status",
      observation: observation,
      alerts: reproductive_alerts
    }
  end

  let(:observation) { "Observação do status" }
  let(:reproductive_alerts) { [] }

  def call_service
    described_class.new(cow: cow).call
  end

  def expected_status(code:, occurred_at:)
    {
      code: code,
      message: I18n.t!("cows.insights.index.status.#{code}"),
      occurred_at: I18n.l(occurred_at.to_date)
    }
  end

  before do
    allow(Cows::Insights::ReproductiveStatus)
      .to receive(:new)
      .with(cow: cow)
      .and_return(instance_double(Cows::Insights::ReproductiveStatus, call: reproductive_status_insight))
  end

  describe "#call" do
    it "retorna status e alerts para o index" do
      result = call_service

      expect(result).to eq(
        status: expected_status(
          code: "open",
          occurred_at: last_heat_at
        ),
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
      context "e a matriz não tem cio cadastrado" do
        let(:last_heat_at) { nil }

        it "retorna observações de pesagem" do
          result = call_service

          expect(result[:status]).to eq(
            expected_status(
              code: "weighing",
              occurred_at: last_weighing_at
            )
          )
        end
      end

      context "e a matriz tem cio cadastrado" do
        it "usa a data do último cio como occurred_at" do
          result = call_service

          expect(result[:status]).to eq(
            expected_status(
              code: "open",
              occurred_at: last_heat_at
            )
          )
        end
      end
    end

    context "quando o status é in_heat" do
      let(:reproductive_status) { :in_heat }

      it "usa a data do último cio como occurred_at" do
        result = call_service

        expect(result[:status]).to eq(
          expected_status(
            code: "in_heat",
            occurred_at: last_heat_at
          )
        )
      end
    end

    context "quando o status é inseminated" do
      let(:reproductive_status) { :inseminated }
      let(:last_insemination_at) { occurred_at }

      it "usa a data da última inseminação como occurred_at" do
        result = call_service

        expect(result[:status]).to eq(
          expected_status(
            code: "inseminated",
            occurred_at: last_insemination_at
          )
        )
      end
    end

    context "quando o status é pregnant" do
      let(:reproductive_status) { :pregnant }
      let(:pregnancy_confirmed_at) { occurred_at }

      it "usa a data da confirmação de prenhez como occurred_at" do
        result = call_service

        expect(result[:status]).to eq(
          expected_status(
            code: "pregnant",
            occurred_at: pregnancy_confirmed_at
          )
        )
      end
    end

    context "quando o status é postpartum" do
      let(:reproductive_status) { :postpartum }
      let(:last_calving_at) { occurred_at }

      it "usa a data do último parto como occurred_at" do
        result = call_service

        expect(result[:status]).to eq(
          expected_status(
            code: "postpartum",
            occurred_at: last_calving_at
          )
        )
      end
    end
  end
end
