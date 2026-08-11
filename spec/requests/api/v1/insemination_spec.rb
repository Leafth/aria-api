require "rails_helper"

RSpec.describe "Api::V1::Events", type: :request do
  let(:tenant) { create(:tenant) }
  let(:headers) do { "X-Tenant-Slug" => tenant.slug } end
  let(:current_user) do build(:user, tenant: tenant) end

  let(:local_bull) do create(:bull, tenant: tenant) end
  let(:company_bull) do create(:bull, :from_company, tenant: tenant) end

  let(:occurred_at) { Time.current.change(usec: 0) }

  let(:cow) do
    create(
      :cow,
      :young,
      :in_heat,
      tenant: tenant,
      last_heat_at: last_heat_at
    )
  end

  let(:last_heat_at) { 2.hours.ago.change(usec: 0) }

  def post_insemination(
    method:,
    bull_id:,
    occurred_at: self.occurred_at
  )
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "insemination",
          occurred_at: occurred_at,
          data: {
            method: method,
            bull_id: bull_id
          }
        }
      },
      headers: headers
  end

  before do
    allow_any_instance_of(AuthenticateRequest)
      .to receive(:authenticate_request!)
      .and_return(true)

    allow_any_instance_of(AuthenticateRequest)
      .to receive(:current_user)
      .and_return(current_user)
  end

  describe "POST /api/v1/cows/:cow_id/events" do
    it "cria evento de inseminação artificial e atualiza status da matriz" do
      occurred_at = Time.current

      post_insemination(
        method: "artificial_insemination",
        bull_id: company_bull.id
      )

      expect(response).to have_http_status(:created)
      expect(cow.reload.reproductive_status).to eq("inseminated")
      expect(cow.last_insemination_at).to be_within(1.second).of(occurred_at)
      expect(Event.last.event_type).to eq("insemination")
    end

    it "cria evento de monta natural e atualiza status da matriz" do
      occurred_at = Time.current

      post_insemination(
        method: "natural_mating",
        bull_id: local_bull.id
      )

      expect(response).to have_http_status(:created)
      expect(cow.reload.reproductive_status).to eq("inseminated")
      expect(cow.last_insemination_at).to be_within(1.second).of(occurred_at)
      expect(Event.last.event_type).to eq("insemination")
    end

    it "retorna 422 quando a matriz não está em cio" do
      cow.update!(reproductive_status: "open", last_heat_at: nil)

      post_insemination(
        method: "artificial_insemination",
        bull_id: company_bull.id
      )

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "retorna 422 quando o cio passou de 24 horas" do
      occurred_at = Time.current

      cow.update!(last_heat_at: occurred_at - 25.hours)

      post_insemination(
        method: "artificial_insemination",
        bull_id: company_bull.id
      )

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "retorna 422 quando o método é inválido" do
      post_insemination(
        method: "outro",
        bull_id: company_bull.id
      )

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "retorna 422 quando o touro não existe" do
      post_insemination(
        method: "artificial_insemination",
        bull_id: SecureRandom.uuid
      )

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "retorna 422 quando inseminação artificial usa touro local" do
      post_insemination(
        method: "artificial_insemination",
        bull_id: local_bull.id
      )

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "retorna 422 quando monta natural usa touro de empresa" do
      post_insemination(
        method: "natural_mating",
        bull_id: company_bull.id
      )

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
