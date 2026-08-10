require "rails_helper"

RSpec.describe "Api::V1::Events", type: :request do
  let(:tenant) { create(:tenant) }
  let(:headers) do { "X-Tenant-Slug" => tenant.slug } end
  let(:current_user) do build(:user, tenant: tenant) end

  let(:cow) do
    create(
      :cow,
      tenant: tenant,
    )
  end

  before do
    allow_any_instance_of(AuthenticateRequest)
      .to receive(:authenticate_request!)
      .and_return(true)

    allow_any_instance_of(AuthenticateRequest)
      .to receive(:current_user)
      .and_return(current_user)
  end

  it "cria evento e permite mudar de calf para heifer" do
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

  it "cria evento e permite mudar de calf para young" do
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "phase_change",
          data: { phase: "young" }
        }
      }, headers: headers

    expect(response).to have_http_status(:created)
    expect(cow.reload.phase).to eq("young")
    expect(Event.last.event_type).to eq("phase_change")
  end

  it "cria evento e permite mudar de heifer para young" do
    cow.update!(phase: "heifer")

    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "phase_change",
          data: { phase: "young" }
        }
      }, headers: headers

    expect(response).to have_http_status(:created)
    expect(cow.reload.phase).to eq("young")
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

  it "retorna 422 se fase for inválida" do
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

  it "retorna 422 se tentar voltar de heifer para calf" do
    cow.update!(phase: "heifer")

    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "phase_change",
          data: { phase: "calf" }
        }
      }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(cow.reload.phase).to eq("heifer")
  end

  it "retorna 422 se tentar voltar de young para heifer" do
    cow.update!(phase: "young")

    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "phase_change",
          data: { phase: "heifer" }
        }
      }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(cow.reload.phase).to eq("young")
  end

  it "retorna 422 se tentar voltar de young para calf" do
    cow.update!(phase: "young")

    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "phase_change",
          data: { phase: "calf" }
        }
      }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(cow.reload.phase).to eq("young")
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
