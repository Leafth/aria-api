module Auth
  class Refresh
    class Error < StandardError; end

    def initialize(tenant:, refresh_token:)
      @tenant = tenant
      @refresh_token = refresh_token
    end

    def call
      session = tenant.auth_sessions.find_by(
        refresh_token_digest: Auth::RefreshToken.digest(refresh_token)
      )

      raise Error, "Refresh token inválido" unless session
      raise Error, "Sessão revogada" if session.revoked?
      raise Error, "Sessão expirada" if session.expired?

      user = session.user
      raise Error, "Usuário inativo" unless user.active?

      new_refresh_token = Auth::RefreshToken.generate_token

      session.update!(
        refresh_token_digest: Auth::RefreshToken.digest(new_refresh_token),
        expires_at: Rails.configuration.x.auth.refresh_token_expiration.from_now
      )

      access_token = Auth::AccessToken.encode(
        user: user,
        tenant: tenant,
        session: session
      )

      {
        access_token: access_token,
        refresh_token: new_refresh_token,
        user: user
      }
    end

    private

    attr_reader :tenant, :refresh_token
  end
end
