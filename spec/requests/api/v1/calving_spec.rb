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
    it "cria evento de parto, atualiza status da matriz e muda fase para primípara" do
      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "calving",
            occurred_at: occurred_at,
            data: {
              observation: "Parto sem complicações"
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:created)
      expect(cow.reload.reproductive_status).to eq("postpartum")
      expect(cow.last_calving_at).to be_within(1.second).of(occurred_at)
      expect(cow.reload.phase).to eq("primiparous")
      expect(Event.last.event_type).to eq("calving")
    end

    it "cria evento de parto, atualiza status da matriz, e muda fase de primípara para multípara" do
      cow.update!(phase: "primiparous")

      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "calving",
            occurred_at: occurred_at,
            data: {
              observation: "Parto sem complicações"
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:created)
      expect(cow.reload.reproductive_status).to eq("postpartum")
      expect(cow.last_calving_at).to be_within(1.second).of(occurred_at)
      expect(cow.reload.phase).to eq("multiparous")
      expect(Event.last.event_type).to eq("calving")
    end

    it "cria evento de parto, atualiza status da matriz, e mantém fase quando multípara" do
      cow.update!(phase: "multiparous")

      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "calving",
            occurred_at: occurred_at,
            data: {
              observation: "Parto sem complicações"
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:created)
      expect(cow.reload.reproductive_status).to eq("postpartum")
      expect(cow.last_calving_at).to be_within(1.second).of(occurred_at)
      expect(cow.reload.phase).to eq("multiparous")
      expect(Event.last.event_type).to eq("calving")
    end

    it "retorna 422 quando a matriz não está prenha" do
      cow.update!(reproductive_status: "inseminated", pregnancy_confirmed_at: nil)

      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "calving",
            occurred_at: occurred_at,
            data: {
              observation: "Parto sem complicações"
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
