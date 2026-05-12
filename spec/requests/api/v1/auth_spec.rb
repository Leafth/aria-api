require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  let!(:tenant) { Tenant.create!(name: "Fazenda", slug: "fazenda-teste", status: :active) }

  let(:headers) { { "X-Tenant-Slug" => tenant.slug } }

  let!(:user) do
    User.create!(
      tenant: tenant,
      name: "User 1",
      email: "user@email.com",
      password: "@Senha123",
      password_confirmation: "@Senha123",
      status: :active
    )
  end

  describe "POST /api/v1/auth/login" do
    it "autentica usuário com credenciais válidas" do
      post "/api/v1/auth/login",
        params: {
          auth: {
            email: user.email,
            password: "@Senha123"
          }
        }, headers: headers

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["access_token"]).to be_present
      expect(body["refresh_token"]).to be_present
      expect(body["expires_in"]).to be_present

      expect(body["user"]).to include(
        "id" => user.id,
        "name" => user.name,
        "email" => user.email,
        "tenant_id" => tenant.id
      )

      expect(response.cookies["access_token"]).to be_present
      expect(response.cookies["refresh_token"]).to be_present
    end

    it "retorna 401 com senha inválida" do
      post "/api/v1/auth/login",
        params: {
          auth: {
            email: user.email,
            password: "senha-errada"
          }
        }, headers: headers

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/auth/refresh" do
    let(:refresh_token) { Auth::RefreshToken.generate_token }

    let!(:session) do
      AuthSession.create!(
        tenant: tenant,
        user: user,
        refresh_token_digest: Auth::RefreshToken.digest(refresh_token),
        expires_at: 1.day.from_now
      )
    end

    it "renova autenticação com refresh token válido via params" do
      post "/api/v1/auth/refresh",
        params: {
          auth: {
            refresh_token: refresh_token
          }
        }, headers: headers

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body["access_token"]).to be_present
      expect(body["refresh_token"]).to be_present
      expect(body["refresh_token"]).not_to eq(refresh_token)
      expect(body["expires_in"]).to be_present

      expect(body["user"]).to include(
        "id" => user.id,
        "name" => user.name,
        "email" => user.email,
        "tenant_id" => tenant.id
      )

      expect(response.cookies["access_token"]).to be_present
      expect(response.cookies["refresh_token"]).to be_present
    end

    it "rotaciona o refresh token da sessão" do
      old_digest = session.refresh_token_digest

      post "/api/v1/auth/refresh",
        params: {
          auth: {
            refresh_token: refresh_token
          }
        }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(session.reload.refresh_token_digest).not_to eq(old_digest)
    end

    it "retorna 401 com refresh token inválido" do
      post "/api/v1/auth/refresh",
        params: {
          auth: {
            refresh_token: "token-invalido"
          }
        }, headers: headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "retorna 401 quando refresh token não é enviado" do
      post "/api/v1/auth/refresh",
        params: {
          auth: {}
        }, headers: headers

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    let(:refresh_token) { Auth::RefreshToken.generate_token }

    let!(:session) do
      AuthSession.create!(
        tenant: tenant,
        user: user,
        refresh_token_digest: Auth::RefreshToken.digest(refresh_token),
        expires_at: 1.day.from_now
      )
    end

    it "realiza logout com refresh token válido" do
      delete "/api/v1/auth/logout",
        params: {
          auth: {
            refresh_token: refresh_token
          }
        }, headers: headers

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)

      expect(body).to eq({})
      expect(session.reload.revoked?).to eq(true)
    end

    it "retorna 401 com refresh token inválido" do
      delete "/api/v1/auth/logout",
        params: {
          auth: {
            refresh_token: "token-invalido"
          }
        }, headers: headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "retorna erro quando refresh token não é enviado" do
      delete "/api/v1/auth/logout",
        params: {
          auth: {}
        }, headers: headers

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
