require "rails_helper"

RSpec.describe Events::PhaseChange do
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
      phase: "calf",
      active: true
    )
  end

  describe "#call" do
    it "cria evento de mudança de fase" do
      params = {
        event_type: "phase_change",
        data: { phase: "heifer" }
      }

      event = described_class.new(cow: cow, params: params).call

      expect(event).to be_persisted
      expect(event.event_type).to eq("phase_change")
      expect(event.data["phase"]).to eq("heifer")
      expect(event.data["previous_phase"]).to eq("calf")
      expect(cow.reload.phase).to eq("heifer")
    end

    it "é inválido sem fase" do
      params = {
        event_type: "phase_change",
        data: {}
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(cow.reload.phase).to eq("calf")
    end

    it "é inválido com fase inválida" do
      params = {
        event_type: "phase_change",
        data: { phase: "outro" }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(cow.reload.phase).to eq("calf")
    end

    it "é inválido se tentar mudar para a mesma fase" do
      params = {
        event_type: "phase_change",
        data: { phase: "calf" }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "é inválido se tentar mudar manualmente para primiparous" do
      params = {
        event_type: "phase_change",
        data: { phase: "primiparous" }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(cow.reload.phase).to eq("calf")
    end

    it "é inválido se tentar mudar fase de uma matriz primiparous" do
      cow.update!(phase: "primiparous")

      params = {
        event_type: "phase_change",
        data: { phase: "young" }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(cow.reload.phase).to eq("primiparous")
    end

    it "é inválido se tentar mudar manualmente para multiparous" do
      params = {
        event_type: "phase_change",
        data: { phase: "multiparous" }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(cow.reload.phase).to eq("calf")
    end

    it "é inválido se tentar mudar fase de uma matriz multiparous" do
      cow.update!(phase: "multiparous")

      params = {
        event_type: "phase_change",
        data: { phase: "young" }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(cow.reload.phase).to eq("multiparous")
    end
  end
end
