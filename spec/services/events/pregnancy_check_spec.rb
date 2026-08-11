require "rails_helper"

RSpec.describe Events::PregnancyCheck do
  let(:occurred_at) { Time.current.change(usec: 0) }

  let(:cow) do
    create(
      :cow,
      :young,
      :inseminated,
      last_heat_at: last_heat_at,
      last_insemination_at: last_insemination_at
    )
  end

  let(:last_heat_at) { 25.hours.ago.change(usec: 0) }
  let(:last_insemination_at) { 24.hours.ago.change(usec: 0) }

  def call_service(result:)
    described_class.new(
      cow: cow,
      params: {
        event_type: "pregnancy_check",
        occurred_at: occurred_at,
        data: {
          result: result
        }
      }
    ).call
  end

  describe "#call" do
    it "cria evento de verificação de gravidez com resultado positivo e atualiza status da matriz" do
      event = call_service(result: "positive")

      expect(event).to be_persisted
      expect(event.event_type).to eq("pregnancy_check")
      expect(event.data["result"]).to eq("positive")

      expect(cow.reload.reproductive_status).to eq("pregnant")
      expect(cow.pregnancy_confirmed_at).to be_within(1.second).of(occurred_at)
    end

    it "cria evento de verificação de gravidez com resultado negativo e atualiza status da matriz" do
      event = call_service(result: "negative")

      expect(event).to be_persisted
      expect(event.event_type).to eq("pregnancy_check")
      expect(event.data["result"]).to eq("negative")

      expect(cow.reload.reproductive_status).to eq("open")
      expect(cow.pregnancy_confirmed_at).to be_nil
    end

    it "é inválido quando a matriz não está inseminada" do
      cow.update!(reproductive_status: "in_heat", last_heat_at: nil, last_insemination_at: nil)

      expect {
        call_service(result: "positive")
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.invalid_pregnancy_check_transition")
      )

      expect(Event.count).to eq(0)

      expect(cow.reload.reproductive_status).to eq("in_heat")
      expect(cow.pregnancy_confirmed_at).to be_nil
    end

    it "é inválido quando resultado é inválido" do
      expect {
        call_service(result: "outro")
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.pregnancy_check.invalid_result")
      )

      expect(Event.count).to eq(0)

      expect(cow.reload.reproductive_status).to eq("inseminated")
      expect(cow.pregnancy_confirmed_at).to be_nil
    end

    it "é inválido sem resultado" do
      expect {
        call_service(result: nil)
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.pregnancy_check.result_required")
      )

      expect(Event.count).to eq(0)

      expect(cow.reload.reproductive_status).to eq("inseminated")
      expect(cow.pregnancy_confirmed_at).to be_nil
    end
  end
end
