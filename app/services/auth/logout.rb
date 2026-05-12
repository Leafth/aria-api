module Auth
  class Logout
    def initialize(tenant:, refresh_token:)
      @tenant = tenant
      @refresh_token = refresh_token
    end

    def call
      raise Error, I18n.t!("auth.errors.missing_refresh_token") if refresh_token.blank?

      session = tenant.auth_sessions.find_by(
        refresh_token_digest: Auth::RefreshToken.digest(refresh_token)
      )

      raise Error, I18n.t!("auth.errors.session_not_found") unless session

      session.revoke!
      true
    end

    private

    attr_reader :tenant, :refresh_token
  end
end
