require "rails_helper"

RSpec.describe "Api::V1::Events", type: :request do
  let!(:tenant) { Tenant.create!(name: "Fazenda", slug: "fazenda-teste", status: :active) }

  let(:breed) { Breed.create!(tenant: tenant, name: "Nelore") }

  let(:headers) { { "X-Tenant-Slug" => tenant.slug } }

  let!(:company) { Company.create!(tenant: tenant, name: "Empresa Teste") }

  let!(:local_bull) do
    tenant.bulls.create!(
      name: "Touro Local",
      breed: breed,
      origin: :local,
      ear_tag: "001"
    )
  end

  let!(:company_bull) do
    tenant.bulls.create!(
      name: "Touro Empresa",
      breed: breed,
      origin: :company,
      company: company
    )
  end

  let(:cow) do
    tenant.cows.create!(
      name: "Mimosa",
      ear_tag: "002",
      birth_date: "2023-01-01",
      breed: breed,
      weight: 180,
      phase: "young",
      reproductive_status: "in_heat",
      last_heat_at: 2.hours.ago,
      active: true
    )
  end

  before do
    allow_any_instance_of(AuthenticateRequest)
      .to receive(:authenticate_request!)
      .and_return(true)

    allow_any_instance_of(AuthenticateRequest)
      .to receive(:current_user)
      .and_return(User.new(tenant: tenant))
  end

  describe "POST /api/v1/cows/:cow_id/events" do
    it "cria evento de inseminação artificial e atualiza status da matriz" do
      occurred_at = Time.current

      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "insemination",
            occurred_at: occurred_at,
            data: {
              method: "artificial_insemination",
              bull_id: company_bull.id
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:created)
      expect(cow.reload.reproductive_status).to eq("inseminated")
      expect(cow.last_insemination_at).to be_within(1.second).of(occurred_at)
      expect(Event.last.event_type).to eq("insemination")
    end

    it "cria evento de monta natural e atualiza status da matriz" do
      occurred_at = Time.current

      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "insemination",
            occurred_at: occurred_at,
            data: {
              method: "natural_mating",
              bull_id: local_bull.id
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:created)
      expect(cow.reload.reproductive_status).to eq("inseminated")
      expect(cow.last_insemination_at).to be_within(1.second).of(occurred_at)
      expect(Event.last.event_type).to eq("insemination")
    end

    it "retorna 422 quando a matriz não está em cio" do
      cow.update!(reproductive_status: "open", last_heat_at: nil)

      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "insemination",
            occurred_at: Time.current,
            data: {
              method: "artificial_insemination",
              bull_id: company_bull.id
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "retorna 422 quando o cio passou de 24 horas" do
      occurred_at = Time.current

      cow.update!(last_heat_at: occurred_at - 25.hours)

      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "insemination",
            occurred_at: occurred_at,
            data: {
              method: "artificial_insemination",
              bull_id: company_bull.id
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "retorna 422 quando o método é inválido" do
      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "insemination",
            occurred_at: Time.current,
            data: {
              method: "outro",
              bull_id: company_bull.id
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "retorna 422 quando o touro não existe" do
      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "insemination",
            occurred_at: Time.current,
            data: {
              method: "artificial_insemination",
              bull_id: SecureRandom.uuid
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "retorna 422 quando inseminação artificial usa touro local" do
      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "insemination",
            occurred_at: Time.current,
            data: {
              method: "artificial_insemination",
              bull_id: local_bull.id
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "retorna 422 quando monta natural usa touro de empresa" do
      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "insemination",
            occurred_at: Time.current,
            data: {
              method: "natural_mating",
              bull_id: company_bull.id
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
