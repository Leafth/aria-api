require "rails_helper"

RSpec.describe Cows::Insights::ForProfile do
  let!(:tenant) do
    Tenant.create!(name: "Fazenda", slug: "fazenda-teste", status: :active)
  end

  let(:cow) do
    tenant.cows.create!(
      name: "Mimosa",
      ear_tag: "001",
      birth_date: "2023-01-01",
      breed: "Nelore",
      weight: weight,
      phase: phase,
      reproductive_status: reproductive_status,
      active: true
    )
  end

  let(:weight) { 90 }
  let(:phase) { "calf" }
  let(:reproductive_status) { "open" }

  let(:reproductive_status_insight) do
    {
      status: reproductive_status,
      message: "Aguardando cio",
      observation: "Sem cio anterior",
      alerts: []
    }
  end

  before do
    allow(Cows::Insights::ReproductiveStatus)
      .to receive(:new)
      .with(cow: cow)
      .and_return(instance_double(Cows::Insights::ReproductiveStatus, call: reproductive_status_insight))
  end

  describe "#call" do
    it "retorna os insights da ficha da matriz" do
      result = described_class.new(cow: cow).call

      expect(result).to eq(
        reproductive_status: reproductive_status_insight,
        weight_insight: {
          current_weight: 90,
          last_weighing_at: nil
        },
        phase_insight: {
          current_phase: "calf",
          message: I18n.t!("cows.insights.profile.phase.adequate")
        },
        recommended_next_action: "heat_detection"
      )
    end

    it "retorna a data da última pesagem no insight de peso" do
      older_weighing_at = 2.days.ago.change(usec: 0)
      latest_weighing_at = 1.day.ago.change(usec: 0)

      Events::Weighing.new(
        cow: cow,
        params: {
          occurred_at: older_weighing_at,
          data: { weight: 95 }
        }
      ).call

      Events::Weighing.new(
        cow: cow,
        params: {
          occurred_at: latest_weighing_at,
          data: { weight: 100 }
        }
      ).call

      result = described_class.new(cow: cow.reload).call

      expect(result[:weight_insight]).to eq(
        current_weight: 100,
        last_weighing_at: latest_weighing_at
      )
    end

    context "quando a fase é bezerra" do
      let(:phase) { "calf" }

      context "e o peso é menor que 100kg" do
        let(:weight) { 99 }

        it "retorna fase adequada" do
          result = described_class.new(cow: cow).call

          expect(result[:phase_insight]).to eq(
            current_phase: "calf",
            message: I18n.t!("cows.insights.profile.phase.adequate")
          )
        end
      end

      context "e o peso é maior ou igual a 100kg" do
        let(:weight) { 100 }

        it "sugere mudar para garrota" do
          result = described_class.new(cow: cow).call

          expect(result[:phase_insight]).to eq(
            current_phase: "calf",
            message: I18n.t!(
              "cows.insights.profile.phase.change_suggested",
              phase: I18n.t!("activerecord.attributes.cow.phases.heifer")
            )
          )
        end
      end

      context "e o peso é maior ou igual a 180kg" do
        let(:weight) { 180 }

        it "sugere mudar para novilha" do
          result = described_class.new(cow: cow).call

          expect(result[:phase_insight]).to eq(
            current_phase: "calf",
            message: I18n.t!(
              "cows.insights.profile.phase.change_suggested",
              phase: I18n.t!("activerecord.attributes.cow.phases.young")
            )
          )
        end
      end
    end

    context "quando a fase é garrota" do
      let(:phase) { "heifer" }

      context "e o peso é menor que 100kg" do
        let(:weight) { 99 }

        it "retorna abaixo do peso esperado" do
          result = described_class.new(cow: cow).call

          expect(result[:phase_insight]).to eq(
            current_phase: "heifer",
            message: I18n.t!("cows.insights.profile.phase.below_weight")
          )
        end
      end

      context "e o peso é maior ou igual a 180kg" do
        let(:weight) { 180 }

        it "sugere mudar para novilha" do
          result = described_class.new(cow: cow).call

          expect(result[:phase_insight]).to eq(
            current_phase: "heifer",
            message: I18n.t!(
              "cows.insights.profile.phase.change_suggested",
              phase: I18n.t!("activerecord.attributes.cow.phases.young")
            )
          )
        end
      end
    end

    context "quando a fase exige no mínimo 180kg" do
      let(:weight) { 179 }

      %w[young primiparous multiparous].each do |current_phase|
        context "e a fase é #{current_phase}" do
          let(:phase) { current_phase }

          it "retorna abaixo do peso esperado" do
            result = described_class.new(cow: cow).call

            expect(result[:phase_insight]).to eq(
              current_phase: current_phase,
              message: I18n.t!("cows.insights.profile.phase.below_weight")
            )
          end
        end
      end
    end

    context "quando define a próxima ação recomendada" do
      {
        "open" => "heat_detection",
        "in_heat" => "insemination",
        "inseminated" => "pregnancy_check",
        "pregnant" => "calving",
        "postpartum" => "heat_detection"
      }.each do |status, action|
        context "quando o status reprodutivo é #{status}" do
          let(:reproductive_status) { status }

          it "retorna #{action}" do
            result = described_class.new(cow: cow).call

            expect(result[:recommended_next_action]).to eq(action)
          end
        end
      end
    end

    context "quando calcula os dias desde o último parto" do
      let(:phase) { "primiparous" }
      let(:reproductive_status) { "open" }
      let(:last_calving_at) { 10.days.ago.change(usec: 0) }

      before do
        cow.update!(last_calving_at: last_calving_at)
      end

      it "retorna os dias desde o último parto quando o parto existe" do
        result = described_class.new(cow: cow).call

        expect(result[:days_since_last_calving]).to eq(10)
      end

      context "quando matriz está prenha" do
        let(:reproductive_status) { "pregnant" }

        it "não retorna os dias desde o último parto" do
          result = described_class.new(cow: cow).call

          expect(result).not_to have_key(:days_since_last_calving)
        end
      end

      context "quando não existe último parto" do
        let(:last_calving_at) { nil }

        it "não retorna os dias desde o último parto" do
          result = described_class.new(cow: cow.reload).call

          expect(result).not_to have_key(:days_since_last_calving)
        end
      end
    end
  end
end
