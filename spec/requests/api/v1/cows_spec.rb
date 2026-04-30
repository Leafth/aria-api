require 'rails_helper'

RSpec.describe "Api::V1::Cows", type: :request do
  let!(:tenant) { Tenant.create!(name: "Fazenda", slug: "fazenda-teste", status: :active) }

  let(:headers) { { "X-Tenant-Slug" => tenant.slug } }

  def cow_params
    {
      name: "Mimosa",
      ear_tag: SecureRandom.hex(3),
      birth_date: "2023-01-01",
      breed: "Nelore",
      weight: 180,
      phase: "calf",
      active: true
    }
  end

  before do
    allow_any_instance_of(AuthenticateRequest)
      .to receive(:authenticate_request!)
      .and_return(true)

    allow_any_instance_of(AuthenticateRequest)
      .to receive(:current_user)
      .and_return(User.new(tenant: tenant))
  end

  describe "POST /api/v1/cows" do
    it "create cow" do
      post "/api/v1/cows", params: { cow: cow_params }, headers: headers
      puts response.body
      expect(response).to have_http_status(:created)
    end

    it "retorna 422 quando nome ausente" do
      post "/api/v1/cows", params: { cow: cow_params.merge(name: nil) },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)

      body = JSON.parse(response.body)
      expect(body["errors"]).to have_key("name")
    end

    it "retorna 422 quando peso é inválido" do
      post "/api/v1/cows", params: { cow: cow_params.merge(weight: -100) },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "retorna 422 quando fase é inválida" do
      post "/api/v1/cows", params: { cow: cow_params.merge(phase: "old") },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "não permite brinco duplicado" do
      tenant.cows.create!(cow_params.merge(ear_tag: "001"))

      post "/api/v1/cows", params: { cow: cow_params.merge(ear_tag: "001") },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/cows" do
    it "lista cows" do
      tenant.cows.create!(cow_params)

      get "/api/v1/cows", headers: headers

      body = JSON.parse(response.body)
      expect(body["data"].size).to eq(1)
    end

    it "aplica paginação" do
      5.times { tenant.cows.create!(cow_params) }

      get '/api/v1/cows?page=1&per_page=2', headers: headers

      body = JSON.parse(response.body)

      expect(body["data"].size).to eq(2)
      expect(body["meta"]["current_page"]).to eq(1)
    end
  end

  describe "GET /api/v1/cows/:id" do
    it "return cow" do
      cow = tenant.cows.create!(cow_params)

      get "/api/v1/cows/#{cow.id}", headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(cow.id)
    end

    it "retorna 404 caso não exista" do
      get "/api/v1/cows/999999", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/cows/:id" do
    it "atualiza dados válidos" do
      cow = tenant.cows.create(cow_params)

      patch "/api/v1/cows/#{cow.id}",
        params: { cow: { name: "Atualizada" } },
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(cow.reload.name).to eq("Atualizada")
    end

    it "não permite inativação por update" do
      cow = tenant.cows.create(cow_params)

      patch "/api/v1/cows/#{cow.id}",
        params: { cow: { active: false } },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "não permite alterar peso" do
      cow = tenant.cows.create(cow_params)

      patch "/api/v1/cows/#{cow.id}",
        params: { cow: { weight: 9999 } },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "não permite alterar fase" do
      cow = tenant.cows.create(cow_params)

      patch "/api/v1/cows/#{cow.id}",
        params: { cow: { phase: "primiparous" } },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "não permite atualizar brinco para valor existente" do
      exists_cow = tenant.cows.create(cow_params)
      new_cow = tenant.cows.create(cow_params.merge(ear_tag: 002))

      patch "/api/v1/cows/#{new_cow.id}",
        params: { cow: { ear_tag: exists_cow.ear_tag } },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
