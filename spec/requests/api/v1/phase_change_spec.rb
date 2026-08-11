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

  def post_phase_change(phase:)
    data = phase.nil? ? {} : { phase: phase }

    post "/api/v1/cows/#{cow.id}/events",
      params: {
        event: {
          event_type: "phase_change",
          data: data
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

  it "cria evento e permite mudar de calf para heifer" do
    post_phase_change(phase: "heifer")

    expect(response).to have_http_status(:created)
    expect(cow.reload.phase).to eq("heifer")
    expect(Event.last.event_type).to eq("phase_change")
  end

  it "cria evento e permite mudar de calf para young" do
    post_phase_change(phase: "young")

    expect(response).to have_http_status(:created)
    expect(cow.reload.phase).to eq("young")
    expect(Event.last.event_type).to eq("phase_change")
  end

  it "cria evento e permite mudar de heifer para young" do
    cow.update!(phase: "heifer")

    post_phase_change(phase: "young")

    expect(response).to have_http_status(:created)
    expect(cow.reload.phase).to eq("young")
    expect(Event.last.event_type).to eq("phase_change")
  end

  it "retorna 422 se fase vier vazia" do
    post_phase_change(phase: nil)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "retorna 422 se fase for inválida" do
    post_phase_change(phase: "outro")

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "retorna 422 se tentar mudar para a mesma fase" do
    post_phase_change(phase: "calf")

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "retorna 422 se tentar voltar de heifer para calf" do
    cow.update!(phase: "heifer")

    post_phase_change(phase: "calf")

    expect(response).to have_http_status(:unprocessable_content)
    expect(cow.reload.phase).to eq("heifer")
  end

  it "retorna 422 se tentar voltar de young para heifer" do
    cow.update!(phase: "young")

    post_phase_change(phase: "heifer")

    expect(response).to have_http_status(:unprocessable_content)
    expect(cow.reload.phase).to eq("young")
  end

  it "retorna 422 se tentar voltar de young para calf" do
    cow.update!(phase: "young")

    post_phase_change(phase: "calf")

    expect(response).to have_http_status(:unprocessable_content)
    expect(cow.reload.phase).to eq("young")
  end

  it "retorna 422 se tentar mudar manualmente para primiparous" do
    post_phase_change(phase: "primiparous")

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "retorna 422 se tentar mudar fase de uma matriz primiparous" do
    cow.update!(phase: "primiparous")

    post_phase_change(phase: "young")

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "retorna 422 se tentar mudar fase de uma matriz multiparous" do
    cow.update!(phase: "multiparous")

    post_phase_change(phase: "young")

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "retorna 422 se tentar mudar manualmente para multiparous" do
    post_phase_change(phase: "multiparous")

    expect(response).to have_http_status(:unprocessable_content)
  end
end
