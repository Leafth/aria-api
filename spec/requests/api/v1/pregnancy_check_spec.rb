require "rails_helper"

RSpec.describe "Api::V1::Events", type: :request do
  let(:tenant) { create(:tenant) }
  let(:headers) do { "X-Tenant-Slug" => tenant.slug } end
  let(:current_user) do build(:user, tenant: tenant) end

  let(:occurred_at) { Time.current.change(usec: 0) }

  let(:cow) do
    create(
      :cow,
      :young,
      :inseminated,
      tenant: tenant,
      last_heat_at: last_heat_at,
      last_insemination_at: last_insemination_at
    )
  end

  let(:last_heat_at) { 25.hours.ago.change(usec: 0) }
  let(:last_insemination_at) { 24.hours.ago.change(usec: 0) }

  before do
    allow_any_instance_of(AuthenticateRequest)
      .to receive(:authenticate_request!)
      .and_return(true)

    allow_any_instance_of(AuthenticateRequest)
      .to receive(:current_user)
      .and_return(current_user)
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
