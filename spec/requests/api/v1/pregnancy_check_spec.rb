require "rails_helper"

RSpec.describe "Api::V1::Events", type: :request do
  let!(:tenant) { Tenant.create!(name: "Fazenda", slug: "fazenda-teste", status: :active) }

  let(:headers) { { "X-Tenant-Slug" => tenant.slug } }

  let(:cow) do
    tenant.cows.create!(
      name: "Mimosa",
      ear_tag: "001",
      birth_date: "2023-01-01",
      breed: "Nelore",
      weight: 180,
      phase: "young",
      reproductive_status: "inseminated",
      last_heat_at: 25.hours.ago,
      last_insemination_at: 24.hours.ago,
      active: true
    )
  end

  let(:occurred_at) { Time.current.change(usec: 0) }

  before do
    allow_any_instance_of(AuthenticateRequest)
      .to receive(:authenticate_request!)
      .and_return(true)

    allow_any_instance_of(AuthenticateRequest)
      .to receive(:current_user)
      .and_return(User.new(tenant: tenant))
  end

  describe "POST /api/v1/cows/:cow_id/events" do
    it "cria evento de verificação de gravidez com resultado positivo e atualiza status da matriz" do
      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "pregnancy_check",
            occurred_at: occurred_at,
            data: {
              result: "positive"
            }
          }
        }, headers: headers

      puts response.body
      expect(response).to have_http_status(:created)
      expect(cow.reload.reproductive_status).to eq("pregnant")
      expect(cow.pregnancy_confirmed_at).to be_within(1.second).of(occurred_at)
      expect(Event.last.event_type).to eq("pregnancy_check")
      expect(Event.last.data["result"]).to eq("positive")
    end

    it "cria evento de verificação de gravidez com resultado negativo e atualiza status da matriz" do
      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "pregnancy_check",
            occurred_at: occurred_at,
            data: {
              result: "negative"
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:created)
      expect(cow.reload.reproductive_status).to eq("open")
      expect(cow.pregnancy_confirmed_at).to be_nil
      expect(Event.last.event_type).to eq("pregnancy_check")
      expect(Event.last.data["result"]).to eq("negative")
    end

    it "retorna 422 quando a matriz não está inseminada" do
      cow.update!(reproductive_status: "in_heat", last_heat_at: nil, last_insemination_at: nil)

      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "pregnancy_check",
            occurred_at: occurred_at,
            data: {
              result: "positive"
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "retorna 422 quando o resultado é inválido" do
      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "pregnancy_check",
            occurred_at: occurred_at,
            data: {
              result: "outro"
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "retorna 422 sem resultado" do
      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "pregnancy_check",
            occurred_at: Time.current.change(usec: 0),
            data: {
              result: nil
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
