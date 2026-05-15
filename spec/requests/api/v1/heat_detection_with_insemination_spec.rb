require "rails_helper"

RSpec.describe "Api::V1::Events", type: :request do
  let!(:tenant) { Tenant.create!(name: "Fazenda", slug: "fazenda-teste", status: :active) }

  let(:headers) { { "X-Tenant-Slug" => tenant.slug } }

  let!(:bull) do
    tenant.bulls.create!(
      name: "Touro Local",
      breed: "Nelore",
      origin: :local,
      ear_tag: "001"
    )
  end

  let(:cow) do
    tenant.cows.create!(
      name: "Mimosa",
      ear_tag: "002",
      birth_date: "2023-01-01",
      breed: "Nelore",
      weight: 180,
      phase: "young",
      reproductive_status: "open",
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
    it "cria detecção de cio e inseminação juntos" do
      heat_occurred_at = Time.zone.parse("2026-05-13 08:00:00")
      insemination_occurred_at = Time.zone.parse("2026-05-13 14:00:00")

      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "heat_detection_with_insemination",
            heat_occurred_at: heat_occurred_at,
            insemination_occurred_at: insemination_occurred_at,
            data: {
              method: "natural_mating",
              bull_id: bull.id
            }
          }
        }, headers: headers

        expect(response).to have_http_status(:created)
        events = cow.events.order(:occurred_at)

        expect(events.second_to_last.event_type).to eq("heat_detection")
        expect(events.last.event_type).to eq("insemination")

        cow.reload

        expect(cow.reproductive_status).to eq("inseminated")
        expect(cow.last_heat_at).to eq(heat_occurred_at)
        expect(cow.last_insemination_at).to eq(insemination_occurred_at)
    end

    it "retorna 422 quando cobertura está fora da janela do cio" do
      heat_occurred_at = Time.zone.parse("2026-05-12 08:00:00")
      insemination_occurred_at = Time.zone.parse("2026-05-13 14:00:00")

      post "/api/v1/cows/#{cow.id}/events",
        params: {
          event: {
            event_type: "heat_detection_with_insemination",
            heat_occurred_at: heat_occurred_at,
            insemination_occurred_at: insemination_occurred_at,
            data: {
              method: "natural_mating",
              bull_id: bull.id
            }
          }
        }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
