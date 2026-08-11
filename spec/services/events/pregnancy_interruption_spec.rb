require "rails_helper"

RSpec.describe Events::PregnancyInterruption do
  let(:occurred_at) { Time.current.change(usec: 0) }

  let(:cow) do
    create(
      :cow,
      :young,
      :pregnant,
      last_heat_at: 286.days.ago.change(usec: 0),
      last_insemination_at: 285.days.ago.change(usec: 0),
      pregnancy_confirmed_at: pregnancy_confirmed_at
    )
  end

  let(:pregnancy_confirmed_at) { 280.days.ago.change(usec: 0) }

  def call_service
    described_class.new(
      cow: cow,
      params: {
        occurred_at: occurred_at,
        data: {
          observation: "Gestação interrompida"
        }
      }
    ).call
  end

  describe "#call" do
    it "cria evento para interrupção de prenhez e atualiza status da matriz" do
      event = call_service

      expect(event).to be_persisted
      expect(event.event_type).to eq("pregnancy_interruption")
      expect(event.occurred_at).to be_within(1.second).of(occurred_at)

      expect(cow.reload.reproductive_status).to eq("open")
      expect(cow.last_pregnancy_interruption_at).to be_within(1.second).of(occurred_at)
    end

    it "é inválido quando a matriz não está prenha" do
      cow.update!(reproductive_status: "inseminated", pregnancy_confirmed_at: nil)

      expect {
        call_service
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.invalid_pregnancy_interruption_transition")
      )

      expect(Event.count).to eq(0)

      expect(cow.reload.reproductive_status).to eq("inseminated")
      expect(cow.last_pregnancy_interruption_at).to be_nil
    end
  end
end
