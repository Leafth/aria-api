require 'rails_helper'

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

  it "cria evento que realiza inativação de cow com reason sale" do
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        "event": {
          event_type: "inactivation",
          data: { reason: "sale" }
        }
      }, headers: headers

    expect(response).to have_http_status(:created)
    expect(cow.reload.active).to eq(false)
  end

  it "cria evento que realiza inativação de cow com reason death" do
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        "event": {
          event_type: "inactivation",
          data: { reason: "death" }
        }
      }, headers: headers

    expect(response).to have_http_status(:created)
    expect(cow.reload.active).to eq(false)
  end

  it "retorna 422 se reason vazia" do
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        "event": {
          event_type: "inactivation",
          data: {}
        }
      }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(cow.reload.active).to eq(true)
  end

  it "retorna 422 se reason inválida" do
    post "/api/v1/cows/#{cow.id}/events",
      params: {
        "event": {
          event_type: "inactivation",
          data: { reason: "outro" }
        }
      }, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(cow.reload.active).to eq(true)
  end
end
