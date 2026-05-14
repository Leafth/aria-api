require "rails_helper"

RSpec.describe Events::Insemination do
  let!(:tenant) do
    Tenant.create!(name: "Fazenda", slug: "fazenda-teste", status: :active)
  end

  let!(:company) { Company.create!(tenant: tenant, name: "Empresa Teste") }

  let!(:local_bull) do
    tenant.bulls.create!(
      name: "Touro Local",
      breed: "Nelore",
      origin: :local,
      ear_tag: "001"
    )
  end

  let!(:company_bull) do
    tenant.bulls.create!(
      name: "Touro Empresa",
      breed: "Nelore",
      origin: :company,
      company: company
    )
  end

  let(:last_heat_at) { 2.hours.ago.change(usec: 0) }
  let(:occurred_at) { Time.current.change(usec: 0) }

  let(:cow) do
    tenant.cows.create!(
      name: "Mimosa",
      ear_tag: "001",
      birth_date: "2023-01-01",
      breed: "Nelore",
      weight: 180,
      phase: "young",
      reproductive_status: "in_heat",
      last_heat_at: last_heat_at,
      active: true
    )
  end

  describe "#call" do
    it "cria evento de inseminação artificial e atualiza status da matriz" do
      params = {
        event_type: "insemination",
        occurred_at: occurred_at,
        data: {
          method: "artificial_insemination",
          bull_id: company_bull.id
        }
      }

      event = described_class.new(cow: cow, params: params).call

      expect(event).to be_persisted
      expect(event.event_type).to eq("insemination")
      expect(event.data["method"]).to eq("artificial_insemination")
      expect(event.data["bull_id"]).to eq(company_bull.id)
      expect(cow.reload.reproductive_status).to eq("inseminated")
      expect(cow.reload.last_insemination_at).to be_within(1.second).of(occurred_at)
    end

    it "cria evento de monta natural e atualiza status da matriz" do
      params = {
        event_type: "insemination",
        occurred_at: occurred_at,
        data: {
          method: "natural_mating",
          bull_id: local_bull.id
        }
      }

      event = described_class.new(cow: cow, params: params).call

      expect(event).to be_persisted
      expect(event.event_type).to eq("insemination")
      expect(event.data["method"]).to eq("natural_mating")
      expect(event.data["bull_id"]).to eq(local_bull.id)
      expect(cow.reload.reproductive_status).to eq("inseminated")
      expect(cow.reload.last_insemination_at).to be_within(1.second).of(occurred_at)
    end

    it "é inválido quando a matriz não está em cio" do
      cow.update!(reproductive_status: "open", last_heat_at: nil)

      params = {
        event_type: "insemination",
        occurred_at: occurred_at,
        data: {
          method: "artificial_insemination",
          bull_id: company_bull.id
        }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.invalid_insemination_transition")
      )

      expect(Event.count).to eq(0)
      expect(cow.reload.reproductive_status).to eq("open")
      expect(cow.reload.last_insemination_at).to be_nil
    end


    it "é inválido quando o cio passou de 24 horas" do
      cow.update!(last_heat_at: occurred_at - 25.hours)

      params = {
        event_type: "insemination",
        occurred_at: occurred_at,
        data: {
          method: "artificial_insemination",
          bull_id: company_bull.id
        }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.insemination.heat_expired")
      )

      expect(Event.count).to eq(0)
      expect(cow.reload.reproductive_status).to eq("in_heat")
      expect(cow.reload.last_insemination_at).to be_nil
    end

    it "é inválido quando o método é inválido" do
      params = {
        event_type: "insemination",
        occurred_at: occurred_at,
        data: {
          method: "outro",
          bull_id: company_bull.id
        }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.insemination.invalid_method")
      )

      expect(Event.count).to eq(0)
      expect(cow.reload.reproductive_status).to eq("in_heat")
      expect(cow.reload.last_insemination_at).to be_nil
    end

    it "é inválido sem touro" do
      params = {
        event_type: "insemination",
        occurred_at: occurred_at,
        data: {
          method: "artificial_insemination",
          bull_id: nil
        }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.insemination.bull_required")
      )

      expect(Event.count).to eq(0)
      expect(cow.reload.reproductive_status).to eq("in_heat")
      expect(cow.reload.last_insemination_at).to be_nil
    end

    it "é inválido quando touro não existe" do
      params = {
        event_type: "insemination",
        occurred_at: occurred_at,
        data: {
          method: "artificial_insemination",
          bull_id: SecureRandom.uuid
        }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.insemination.bull_not_found")
      )

      expect(Event.count).to eq(0)
      expect(cow.reload.reproductive_status).to eq("in_heat")
      expect(cow.reload.last_insemination_at).to be_nil
    end

    it "é inválido quando inseminação artificial usa touro local" do
      params = {
        event_type: "insemination",
        occurred_at: occurred_at,
        data: {
          method: "artificial_insemination",
          bull_id: local_bull.id
        }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.insemination.artificial_insemination_requires_company_bull")
      )

      expect(Event.count).to eq(0)
      expect(cow.reload.reproductive_status).to eq("in_heat")
      expect(cow.reload.last_insemination_at).to be_nil
    end

    it "é inválido quando monta natural usa touro de empresa" do
      params = {
        event_type: "insemination",
        occurred_at: occurred_at,
        data: {
          method: "natural_mating",
          bull_id: company_bull.id
        }
      }

      expect {
        described_class.new(cow: cow, params: params).call
      }.to raise_error(
        Events::Error,
        I18n.t!("events.errors.insemination.natural_mating_requires_local_bull")
      )

      expect(Event.count).to eq(0)
      expect(cow.reload.reproductive_status).to eq("in_heat")
      expect(cow.reload.last_insemination_at).to be_nil
    end
  end
end
