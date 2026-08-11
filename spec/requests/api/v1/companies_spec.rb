require "rails_helper"

RSpec.describe "Api::V1::Companies", type: :request do
  let(:tenant) { create(:tenant) }
  let(:headers) do { "X-Tenant-Slug" => tenant.slug } end
  let(:current_user) do build(:user, tenant: tenant) end

  def response_body
    JSON.parse(response.body)
  end

  before do
    allow_any_instance_of(AuthenticateRequest)
      .to receive(:authenticate_request!)
      .and_return(true)

    allow_any_instance_of(AuthenticateRequest)
      .to receive(:current_user)
      .and_return(current_user)
  end

  describe "POST /api/v1/companies" do
    it "cria uma empresa" do
      expect {
        post "/api/v1/companies",
          params: {
            company: {
              name: "Empresa 1"
            }
          }, headers: headers
      }.to change(Company, :count).by(1)

      expect(response).to have_http_status(:created)

      body = response_body

      expect(body["name"]).to eq("Empresa 1")
    end
  end

  describe "GET /api/v1/companies" do
    it "lista empresas com paginação" do
      create(
        :company,
        tenant: tenant,
      )

      get "/api/v1/companies", headers: headers

      expect(response).to have_http_status(:ok)

      body = response_body

      expect(body["data"].size).to eq(1)
      expect(body["meta"]).to be_present
    end
  end

  describe "GET /api/v1/companies/:id" do
    it "exibe uma empresa" do
      company = create(
        :company,
        tenant: tenant,
        name: "Empresa 1"
      )

      get "/api/v1/companies/#{company.id}", headers: headers

      expect(response).to have_http_status(:ok)

      body = response_body

      expect(body["id"]).to eq(company.id)
      expect(body["name"]).to eq("Empresa 1")
    end
  end

  describe "PATCH /api/v1/companies/:id" do
    it "atualiza uma empresa" do
      company = create(
        :company,
        tenant: tenant,
        description: "Descrição antiga"
      )

      patch "/api/v1/companies/#{company.id}",
        params: {
          company: {
            name: "Empresa Atualizada",
            description: "Descrição atualizada"
          }
        }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(company.reload.name).to eq("Empresa Atualizada")
      expect(company.description).to eq("Descrição atualizada")

      body = response_body

      expect(body["id"]).to eq(company.id)
      expect(body["name"]).to eq("Empresa Atualizada")
      expect(body["description"]).to eq("Descrição atualizada")
    end
  end

  describe "DELETE /api/v1/companies/:id" do
    it "remove uma empresa" do
      company = create(
        :company,
        tenant: tenant,
      )

      expect {
        delete "/api/v1/companies/#{company.id}", headers: headers
      }.to change(Company, :count).by(-1)

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_blank
    end
  end
end
