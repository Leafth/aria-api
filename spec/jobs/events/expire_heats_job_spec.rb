require "rails_helper"

RSpec.describe Events::ExpireHeatsJob, type: :job do
  let(:cow) do create(:cow) end

  describe "#perform" do
    it "expira cios vencidos" do
      cow.update!(reproductive_status: :in_heat, last_heat_at: 25.hours.ago)

      described_class.perform_now

      expect(cow.reload.reproductive_status).to eq("open")
    end

    it "não expira cios dentro da janela de validade" do
      cow.update!(reproductive_status: :in_heat, last_heat_at: 2.hours.ago)

      described_class.perform_now

      expect(cow.reload.reproductive_status).to eq("in_heat")
    end

    it "não altera matrizes que não estão em cio" do
      cow.update!(reproductive_status: :inseminated, last_heat_at: 25.hours.ago)

      described_class.perform_now

      expect(cow.reload.reproductive_status).to eq("inseminated")
    end
  end
end
