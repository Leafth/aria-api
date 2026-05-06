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

  it "cria evento de mudança de fase" do
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "phase_change",
          data: { phase: "heifer" }
        }
      }, headers: headers

    expect(response).to have_http_status(:created)
    expect(cow.reload.phase).to eq("heifer")
    expect(Event.last.event_type).to eq("phase_change")
  end

  it "retorna 422 se fase vier vazia" do
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "phase_change",
          data: {}
        }
      }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "retorna 422 se phase for inválida" do
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "phase_change",
          data: { phase: "outro" }
        }
      }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "retorna 422 se tentar mudar para a mesma fase" do
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "phase_change",
          data: { phase: "calf" }
        }
      }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "retorna 422 se tentar mudar manualmente para primiparous" do
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "phase_change",
          data: { phase: "primiparous" }
        }
      }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "retorna 422 se tentar mudar fase de uma matriz primiparous" do
    cow.update!(phase: "primiparous")

    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "phase_change",
          data: { phase: "young" }
        }
      }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "retorna 422 se tentar mudar fase de uma matriz multiparous" do
    cow.update!(phase: "multiparous")

    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "phase_change",
          data: { phase: "young" }
        }
      }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "retorna 422 se tentar mudar manualmente para multiparous" do
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "phase_change",
          data: { phase: "multiparous" }
        }
      }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
