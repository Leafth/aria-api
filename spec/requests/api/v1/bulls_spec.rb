require "rails_helper"

RSpec.describe "Api::V1::Bulls", type: :request do
  let(:tenant) { create(:tenant) }
  let(:breed) { create(:breed, tenant: tenant, name: "Nelore") }
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

  describe "POST /api/v1/bulls" do
    it "cria um touro" do
      expect {
        post "/api/v1/bulls",
          params: {
            bull: {
              name: "Touro 1",
              breed_name: "nelore",
              origin: "local",
              ear_tag: "001"
            }
          }, headers: headers
      }.to change(Bull, :count).by(1)

      expect(response).to have_http_status(:created)

      body = response_body

      expect(body["name"]).to eq("Touro 1")
      expect(body["breed"]).to eq("Nelore")
      expect(body["origin"]).to eq("local")
      expect(body["ear_tag"]).to eq("001")
    end
  end

  describe "GET /api/v1/bulls" do
    it "lista touros com paginação" do
      create(
        :bull,
        tenant: tenant,
        breed: breed
      )

      get "/api/v1/bulls", headers: headers

      expect(response).to have_http_status(:ok)

      body = response_body

      expect(body["data"].size).to eq(1)
      expect(body["meta"]).to be_present
    end
  end

  describe "GET /api/v1/bulls/:id" do
    it "exibe um touro" do
      bull = create(
        :bull,
        tenant: tenant,
        breed: breed,
        name: "Touro 1"
      )

      get "/api/v1/bulls/#{bull.id}", headers: headers

      expect(response).to have_http_status(:ok)

      body = response_body

      expect(body["id"]).to eq(bull.id)
      expect(body["name"]).to eq("Touro 1")
    end
  end

  describe "PATCH /api/v1/bulls/:id" do
    it "atualiza um touro" do
      bull = create(
        :bull,
        tenant: tenant,
        breed: breed,
      )

      patch "/api/v1/bulls/#{bull.id}",
        params: {
          bull: {
            name: "Touro Atualizado"
          }
        }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(bull.reload.name).to eq("Touro Atualizado")

      body = response_body

      expect(body["id"]).to eq(bull.id)
      expect(body["name"]).to eq("Touro Atualizado")
    end
  end

  describe "DELETE /api/v1/bulls/:id" do
    it "remove um touro" do
      bull = create(
        :bull,
        tenant: tenant,
        breed: breed
      )

      expect {
        delete "/api/v1/bulls/#{bull.id}", headers: headers
      }.to change(Bull, :count).by(-1)

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_blank
    end
  end
end
