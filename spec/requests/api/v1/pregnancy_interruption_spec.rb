require "rails_helper"

RSpec.describe "Api::V1::Events", type: :request do
  let!(:tenant) { Tenant.create!(name: "Fazenda", slug: "fazenda-teste", status: :active) }

  let(:breed) { Breed.create!(tenant: tenant, name: "Nelore") }

  let(:headers) { { "X-Tenant-Slug" => tenant.slug } }

  let(:cow) do
    tenant.cows.create!(
      name: "Mimosa",
      ear_tag: "001",
      birth_date: "2023-01-01",
      breed: breed,
      weight: 180,
      phase: "young",
      reproductive_status: "pregnant",
      last_heat_at: 286.days.ago,
      last_insemination_at: 285.days.ago,
      pregnancy_confirmed_at: 280.days.ago,
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
    it "cria evento de interrupção de prenhez e atualiza status da matriz" do
      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "pregnancy_interruption",
            occurred_at: occurred_at,
            data: {
              observation: "Gestação interrompida"
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:created)
      expect(cow.reload.reproductive_status).to eq("open")
      expect(cow.last_pregnancy_interruption_at).to be_within(1.second).of(occurred_at)
      expect(Event.last.event_type).to eq("pregnancy_interruption")
    end

    it "retorna 422 quando a matriz não está prenha" do
      cow.update!(reproductive_status: "inseminated", pregnancy_confirmed_at: nil)

      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "pregnancy_interruption",
            occurred_at: occurred_at,
            data: {
              observation: "Gestação interrompida"
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(cow.reload.reproductive_status).to eq("inseminated")
      expect(cow.last_pregnancy_interruption_at).to be_nil
      expect(Event.count).to eq(0)
    end
  end
end
