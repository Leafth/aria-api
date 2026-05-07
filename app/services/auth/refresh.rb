module Auth
  class Refresh
    def initialize(tenant:, refresh_token:)
      @tenant = tenant
      @refresh_token = refresh_token
    end

    def call
      raise Error, I18n.t!("auth.errors.missing_refresh_token") if refresh_token.blank?

      session = tenant.auth_sessions.find_by(
        refresh_token_digest: Auth::RefreshToken.digest(refresh_token)
      )

      raise Error, I18n.t!("auth.errors.invalid_refresh_token") unless session
      raise Error, I18n.t!("auth.errors.revoked_session") if session.revoked?
      raise Error, I18n.t!("auth.errors.expired_session")  if session.expired?

      user = session.user
      raise Error,  I18n.t!("auth.errors.inactive_user") unless user.active?

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
