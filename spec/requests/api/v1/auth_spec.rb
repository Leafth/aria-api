require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  let(:tenant) { create(:tenant) }
  let(:headers) { { "X-Tenant-Slug" => tenant.slug } }
  let(:user) do create(:user, tenant: tenant) end

  def post_login(email:, password:)
    post "/api/v1/auth/login",
      params: {
        auth: {
          email: email,
          password: password
        }
      },
      headers: headers
  end

  def post_refresh(refresh_token:)
    post "/api/v1/auth/refresh",
      params: {
        auth: {
          refresh_token: refresh_token
        }
      },
      headers: headers
  end

  def delete_logout(refresh_token:)
    delete "/api/v1/auth/logout",
      params: {
        auth: {
          refresh_token: refresh_token
        }
      },
      headers: headers
  end

  def response_body
    JSON.parse(response.body)
  end

  describe "POST /api/v1/auth/login" do
    it "autentica usuário com credenciais válidas" do
      post_login(
        email: user.email,
        password: "@Senha123"
      )

      expect(response).to have_http_status(:ok)

      body = response_body

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
      post_login(
        email: user.email,
        password: "senha-errada"
      )

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/auth/refresh" do
    let(:refresh_token) { Auth::RefreshToken.generate_token }

    let!(:session) do
      create(
        :auth_session,
        tenant: tenant,
        user: user,
        refresh_token_digest: Auth::RefreshToken.digest(refresh_token),
        expires_at: 1.day.from_now
      )
    end

    it "renova autenticação com refresh token válido via params" do
      post_refresh(refresh_token: refresh_token)

      expect(response).to have_http_status(:ok)

      body = response_body

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

      post_refresh(refresh_token: refresh_token)

      expect(response).to have_http_status(:ok)
      expect(session.reload.refresh_token_digest).not_to eq(old_digest)
    end

    it "retorna 401 com refresh token inválido" do
      post_refresh(refresh_token: "token-invalido")

      expect(response).to have_http_status(:unauthorized)
    end

    it "retorna 401 quando refresh token não é enviado" do
      post_refresh(refresh_token: nil)

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    let(:refresh_token) { Auth::RefreshToken.generate_token }

    let!(:session) do
      create(
        :auth_session,
        tenant: tenant,
        user: user,
        refresh_token_digest: Auth::RefreshToken.digest(refresh_token),
        expires_at: 1.day.from_now
      )
    end

    it "realiza logout com refresh token válido" do
      delete_logout(refresh_token: refresh_token)

      expect(response).to have_http_status(:ok)

      expect(response_body).to eq({})
      expect(session.reload.revoked?).to eq(true)
    end

    it "retorna 401 com refresh token inválido" do
      delete_logout(refresh_token: "token-invalido")

      expect(response).to have_http_status(:unauthorized)
    end

    it "retorna 401 quando refresh token não é enviado" do
      delete_logout(refresh_token: nil)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
