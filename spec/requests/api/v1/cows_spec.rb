require 'rails_helper'

RSpec.describe "Api::V1::Cows", type: :request do
  let!(:tenant) { Tenant.create!(name: "Fazenda", slug: "fazenda-teste", status: :active) }

  let(:headers) { { "X-Tenant-Slug" => tenant.slug } }

  before do
    allow_any_instance_of(AuthenticateRequest)
      .to receive(:authenticate_request!)
      .and_return(true)

    allow_any_instance_of(AuthenticateRequest)
      .to receive(:current_user)
      .and_return(User.new(tenant: tenant))
  end

  describe "POST /api/v1/cows" do
    it "cria uma matriz" do
      expect {
        post "/api/v1/cows",
          params: {
            cow: {
              name: "Mimosa",
              ear_tag: "001",
              birth_date: "2023-01-01",
              breed: "Nelore",
              weight: 180,
              phase: "calf",
              active: true
            }
          }, headers: headers
      }.to change(Cow, :count).by(1)

      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)

      expect(body["name"]).to eq("Mimosa")
    end
  end

  describe "GET /api/v1/cows" do
    it "lista matrizes com paginação" do
      tenant.cows.create!(
        name: "Mimosa",
        ear_tag: "001",
        birth_date: "2023-01-01",
        breed: "Nelore",
        weight: 180,
        phase: "calf",
        active: true
      )

      get "/api/v1/cows", headers: headers

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["data"].size).to eq(1)
      expect(body["meta"]).to be_present
    end
  end

  describe "GET /api/v1/cows/:id" do
    it "exibe uma matriz" do
      cow = tenant.cows.create!(
        name: "Mimosa",
        ear_tag: "001",
        birth_date: "2023-01-01",
        breed: "Nelore",
        weight: 180,
        phase: "calf",
        active: true
      )

      get "/api/v1/cows/#{cow.id}", headers: headers

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["id"]).to eq(cow.id)
      expect(body["name"]).to eq("Mimosa")
    end
  end

  describe "PATCH /api/v1/cows/:id" do
    it "atualiza uma matriz" do
      cow = tenant.cows.create!(
        name: "Mimosa",
        ear_tag: "001",
        birth_date: "2023-01-01",
        breed: "Nelore",
        weight: 180,
        phase: "calf",
        active: true
      )

      patch "/api/v1/cows/#{cow.id}",
        params: {
          cow: {
            name: "Mimosa Atualizada"
          }
        }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(cow.reload.name).to eq("Mimosa Atualizada")

      body = JSON.parse(response.body)

      expect(body["id"]).to eq(cow.id)
      expect(body["name"]).to eq("Mimosa Atualizada")
    end
  end

  describe "DELETE /api/v1/cows/:id" do
    it "remove uma matriz" do
      cow = tenant.cows.create!(
        name: "Mimosa",
        ear_tag: "001",
        birth_date: "2023-01-01",
        breed: "Nelore",
        weight: 180,
        phase: "calf",
        active: true
      )

      expect {
        delete "/api/v1/cows/#{cow.id}", headers: headers
      }.to change(Cow, :count).by(-1)

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_blank
    end
  end
end
