require "rails_helper"

RSpec.describe Events::PhaseChange do
  let(:cow) { create(:cow) }

  def call_service(phase:)
    described_class.new(
      cow: cow,
      params: {
        event_type: "phase_change",
        data: phase.nil? ? {} : { phase: phase }
      }
    ).call
  end

  describe "#call" do
    it "cria evento e permite mudar de calf para heifer" do
      event = call_service(phase: "heifer")

      expect(event).to be_persisted
      expect(event.event_type).to eq("phase_change")
      expect(event.data["phase"]).to eq("heifer")
      expect(event.data["previous_phase"]).to eq("calf")
      expect(cow.reload.phase).to eq("heifer")
    end

    it "cria evento e permite mudar de calf para young" do
      event = call_service(phase: "young")

      expect(event).to be_persisted
      expect(event.event_type).to eq("phase_change")
      expect(event.data["phase"]).to eq("young")
      expect(event.data["previous_phase"]).to eq("calf")
      expect(cow.reload.phase).to eq("young")
    end

    it "cria evento e permite mudar de heifer para young" do
      cow.update!(phase: :heifer)

      event = call_service(phase: "young")

      expect(event).to be_persisted
      expect(event.event_type).to eq("phase_change")
      expect(event.data["phase"]).to eq("young")
      expect(event.data["previous_phase"]).to eq("heifer")
      expect(cow.reload.phase).to eq("young")
    end

    it "é inválido sem fase" do
      expect {
        call_service(phase: nil)
      }.to raise_error(Events::Error)

      expect(cow.reload.phase).to eq("calf")
    end

    it "é inválido com fase inválida" do
      expect {
        call_service(phase: "outro")
      }.to raise_error(Events::Error)

      expect(cow.reload.phase).to eq("calf")
    end

    it "é inválido se tentar mudar para a mesma fase" do
      expect {
        call_service(phase: "calf")
      }.to raise_error(Events::Error)
    end

    it "é inválido se tentar voltar de heifer para calf" do
      cow.update!(phase: :heifer)

      expect {
        call_service(phase: "calf")
      }.to raise_error(Events::Error)

      expect(cow.reload.phase).to eq("heifer")
    end

    it "é inválido se tentar voltar de young para heifer" do
      cow.update!(phase: :young)

      expect {
        call_service(phase: "heifer")
      }.to raise_error(Events::Error)

      expect(cow.reload.phase).to eq("young")
    end

    it "é inválido se tentar voltar de young para calf" do
      cow.update!(phase: :young)

      expect {
        call_service(phase: "calf")
      }.to raise_error(Events::Error)

      expect(cow.reload.phase).to eq("young")
    end

    it "é inválido se tentar mudar manualmente para primiparous" do
      expect {
        call_service(phase: "primiparous")
      }.to raise_error(Events::Error)

      expect(cow.reload.phase).to eq("calf")
    end

    it "é inválido se tentar mudar fase de uma matriz primiparous" do
      cow.update!(phase: :primiparous)

      expect {
        call_service(phase: "young")
      }.to raise_error(Events::Error)

      expect(cow.reload.phase).to eq("primiparous")
    end

    it "é inválido se tentar mudar manualmente para multiparous" do
      expect {
        call_service(phase: "multiparous")
      }.to raise_error(Events::Error)

      expect(cow.reload.phase).to eq("calf")
    end

    it "é inválido se tentar mudar fase de uma matriz multiparous" do
      cow.update!(phase: :multiparous)

      expect {
        call_service(phase: "young")
      }.to raise_error(Events::Error)

      expect(cow.reload.phase).to eq("multiparous")
    end
  end
end
