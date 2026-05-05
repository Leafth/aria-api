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
      phase: "calf",
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

  it "cria evento de pesagem" do
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        "event": {
          event_type: "weighing",
          data: { weight: 200 }
        }
      }, headers: headers, as: :json

    expect(response).to have_http_status(:created)
    expect(cow.reload.weight).to eq(200)
    expect(Event.last.event_type).to eq("weighing")
  end

  it "retorna 422 se weight vazio" do
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        "event": {
          event_type: "weighing",
          data: {}
        }
      }, headers: headers, as: :json


    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "retorna 422 se weight negativo" do
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        "event": {
          event_type: "weighing",
          data: { weight: -200 }
        }
      }, headers: headers, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
