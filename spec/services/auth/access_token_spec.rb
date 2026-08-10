require "rails_helper"

RSpec.describe Auth::AccessToken do
  let(:user) { create(:user) }
  let(:tenant) { user.tenant }
  let(:session) { create(:auth_session, user: user, tenant: tenant) }

  describe ".encode" do
    it "gera um token JWT válido com payload esperado" do
      token = described_class.encode(
        user: user,
        tenant: tenant,
        session: session
      )

      decoded_token = JWT.decode(
        token,
        Rails.configuration.x.auth.access_token_secret,
        true,
        { algorithm: described_class::ALGORITHM }
      )

      payload = decoded_token.first.with_indifferent_access
      header = decoded_token.last.with_indifferent_access

      expect(header[:alg]).to eq("HS256")

      expect(payload[:sub]).to eq(user.id)
      expect(payload[:tenant_id]).to eq(tenant.id)
      expect(payload[:session_id]).to eq(session.id)
      expect(payload[:email]).to eq(user.email)
      expect(payload[:iat]).to be_present
      expect(payload[:exp]).to be_present
      expect(payload[:exp]).to be > Time.current.to_i
    end
  end

  describe ".decode" do
    it "inválido quando token é inválido" do
      expect {
        described_class.decode("token-inválido")
      }.to raise_error(JWT::DecodeError)
    end

    it "inválido quando token está expirado" do
      expired_payload = {
        sub: user.id,
        tenant_id: tenant.id,
        session_id: session.id,
        email: user.email,
        iat: 2.hours.ago.to_i,
        exp: 1.hour.ago.to_i
      }

      token = JWT.encode(
        expired_payload,
        Rails.configuration.x.auth.access_token_secret,
        described_class::ALGORITHM
      )

      expect {
        described_class.decode(token)
      }.to raise_error(JWT::ExpiredSignature)
    end
  end
end
