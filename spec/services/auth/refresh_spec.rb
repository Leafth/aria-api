require "rails_helper"

RSpec.describe Auth::Refresh do
  let(:refresh_token) { Auth::RefreshToken.generate_token }
  let(:user) { create(:user) }
  let(:tenant) { user.tenant }

  let!(:session) do
    create(
      :auth_session,
      user: user,
      tenant: tenant,
      refresh_token_digest: Auth::RefreshToken.digest(refresh_token)
    )
  end

  def call_service(attrs = {})
    params = {
      tenant: tenant,
      refresh_token: refresh_token
    }.merge(attrs)

    described_class.new(**params).call
  end

  describe "#call" do
    it "renova autenticação com refresh token válido" do
      result = call_service

      expect(result[:access_token]).to be_present
      expect(result[:refresh_token]).to be_present
      expect(result[:refresh_token]).not_to eq(refresh_token)
      expect(result[:user]).to eq(user)
    end

    it "atualiza digest do refresh token da sessão" do
      result = call_service

      expect(session.reload.refresh_token_digest).to eq(
        Auth::RefreshToken.digest(result[:refresh_token])
      )
    end

    it "atualiza expiração da sessão" do
      old_expires_at = session.expires_at

      call_service

      expect(session.reload.expires_at).to be > old_expires_at
    end

    it "gera access token válido" do
      result = call_service

      payload = Auth::AccessToken.decode(result[:access_token])

      expect(payload[:sub]).to eq(user.id)
      expect(payload[:tenant_id]).to eq(tenant.id)
      expect(payload[:session_id]).to eq(session.id)
      expect(payload[:email]).to eq(user.email)
    end

    it "inválido sem refresh token" do
      expect {
        call_service(refresh_token: nil)
      }.to raise_error(Auth::Error, I18n.t!("auth.errors.missing_refresh_token"))
    end

    it "inválido se refresh token inválido" do
      expect {
        call_service(refresh_token: "token-invalido")
      }.to raise_error(Auth::Error, I18n.t!("auth.errors.invalid_refresh_token"))
    end

    it "inválido com sessão revogada" do
      session.revoke!

      expect {
        call_service
      }.to raise_error(Auth::Error, I18n.t!("auth.errors.revoked_session"))
    end

    it "inválido com sessão expirada" do
      session.update!(expires_at: 1.day.ago)

      expect {
        call_service
      }.to raise_error(Auth::Error, I18n.t!("auth.errors.expired_session"))
    end

    it "inválido com usuário inativo" do
      user.update!(status: :inactive)

      expect {
        call_service
      }.to raise_error(Auth::Error, I18n.t!("auth.errors.inactive_user"))
    end
  end
end
