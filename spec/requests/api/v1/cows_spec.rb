require 'rails_helper'

RSpec.describe "Api::V1::Cows", type: :request do
  let!(:tenant) { Tenant.create!(name: "Fazenda", slug: "fazenda-teste", status: :active) }

  let(:headers) { { "X-Tenant-Slug" => tenant.slug } }

  def cow_params
    {
      name: "Mimosa",
      ear_tag: "001",
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
      tenant.cows.create!(cow_params)

      post "/api/v1/cows", params: { cow: cow_params },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
