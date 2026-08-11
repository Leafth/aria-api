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
      :pregnant,
      tenant: tenant,
      last_heat_at: 286.days.ago.change(usec: 0),
      last_insemination_at: 285.days.ago.change(usec: 0),
      pregnancy_confirmed_at: pregnancy_confirmed_at
    )
  end

  let(:pregnancy_confirmed_at) { 280.days.ago.change(usec: 0) }

  def post_pregnancy_interruption
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "pregnancy_interruption",
          occurred_at: occurred_at,
          data: {
            observation: "Gestação interrompida"
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
    it "cria evento de interrupção de prenhez e atualiza status da matriz" do
      post_pregnancy_interruption

      expect(response).to have_http_status(:created)
      expect(cow.reload.reproductive_status).to eq("open")
      expect(cow.last_pregnancy_interruption_at).to be_within(1.second).of(occurred_at)
      expect(Event.last.event_type).to eq("pregnancy_interruption")
    end

    it "retorna 422 quando a matriz não está prenha" do
      cow.update!(reproductive_status: "inseminated", pregnancy_confirmed_at: nil)

      post_pregnancy_interruption

      expect(response).to have_http_status(:unprocessable_entity)
      expect(cow.reload.reproductive_status).to eq("inseminated")
      expect(cow.last_pregnancy_interruption_at).to be_nil
      expect(Event.count).to eq(0)
    end
  end
end
