require "rails_helper"

RSpec.describe "Api::V1::Events", type: :request do
  let(:tenant) { create(:tenant) }
  let(:headers) do { "X-Tenant-Slug" => tenant.slug } end
  let(:current_user) do build(:user, tenant: tenant) end

  let(:cow) do
    create(
      :cow,
      :open,
      tenant: tenant,
    )
  end

  def post_heat_detection(
    occurred_at: Time.current,
    observation: "Cio observado visualmente"
  )
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "heat_detection",
          occurred_at: occurred_at,
          data: {
            observation: observation
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
    it "cria evento de detecção do cio atual e atualiza status da matriz" do
      occurred_at = 1.hour.ago

      post_heat_detection(occurred_at: occurred_at)

      expect(response).to have_http_status(:created)
      expect(cow.reload.reproductive_status).to eq("in_heat")
      expect(cow.last_heat_at).to be_within(1.second).of(occurred_at)
      expect(Event.last.event_type).to eq("heat_detection")
    end

    it "cria evento de detecção de cio passado e mantém status da matriz como open" do
      occurred_at = 25.hours.ago

      post_heat_detection(
        occurred_at: occurred_at,
        observation: "Cio antigo registrado"
      )

      expect(response).to have_http_status(:created)
      expect(cow.reload.reproductive_status).to eq("open")
      expect(cow.last_heat_at).to be_within(1.second).of(occurred_at)
      expect(Event.last.event_type).to eq("heat_detection")
    end

    it "retorna 422 quando a matriz já está com cio ativo" do
      last_heat_at = 1.hour.ago

      cow.update!(reproductive_status: "in_heat", last_heat_at: last_heat_at)

      post_heat_detection(
        observation: "Nova tentativa de cio"
      )

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "não cria evento quando a matriz não está em estado permitido para cio" do
      cow.update!(reproductive_status: "inseminated")

      post_heat_detection(
        observation: "Animal apresentou sinais de cio"
      )

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
