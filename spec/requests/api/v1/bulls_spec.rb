require "rails_helper"

RSpec.describe "Api::V1::Bulls", type: :request do
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

  describe "POST /api/v1/bulls" do
    it "cria um touro" do
      expect {
        post "/api/v1/bulls",
          params: {
            bull: {
              name: "Touro 1",
              breed: "Nelore",
              origin: "local",
              ear_tag: "001"
            }
          }, headers: headers
      }.to change(Bull, :count).by(1)

      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)

      expect(body["name"]).to eq("Touro 1")
      expect(body["breed"]).to eq("Nelore")
      expect(body["origin"]).to eq("local")
      expect(body["ear_tag"]).to eq("001")
    end
  end

  describe "GET /api/v1/bulls" do
    it "lista touros com paginação" do
      tenant.bulls.create!(
        name: "Touro 1",
        breed: "Nelore",
        origin: "local",
        ear_tag: "001"
      )

      get "/api/v1/bulls", headers: headers

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["data"].size).to eq(1)
      expect(body["meta"]).to be_present
    end
  end

  describe "GET /api/v1/bulls/:id" do
    it "exibe um touro" do
      bull = tenant.bulls.create!(
        name: "Touro 1",
        breed: "Nelore",
        origin: "local",
        ear_tag: "001"
      )

      get "/api/v1/bulls/#{bull.id}", headers: headers

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["id"]).to eq(bull.id)
      expect(body["name"]).to eq("Touro 1")
    end
  end

  describe "PATCH /api/v1/bulls/:id" do
    it "atualiza um touro" do
      bull = tenant.bulls.create!(
        name: "Touro 1",
        breed: "Nelore",
        origin: "local",
        ear_tag: "001"
      )

      patch "/api/v1/bulls/#{bull.id}",
        params: {
          bull: {
            name: "Touro Atualizado"
          }
        }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(bull.reload.name).to eq("Touro Atualizado")

      body = JSON.parse(response.body)

      expect(body["id"]).to eq(bull.id)
      expect(body["name"]).to eq("Touro Atualizado")
    end
  end

  describe "DELETE /api/v1/bulls/:id" do
    it "remove um touro" do
      bull = tenant.bulls.create!(
        name: "Touro 1",
        breed: "Nelore",
        origin: "local",
        ear_tag: "001"
      )

      expect {
        delete "/api/v1/bulls/#{bull.id}", headers: headers
      }.to change(Bull, :count).by(-1)

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_blank
    end
  end
end
