module Auth
  class Logout
    class Error < StandardError; end

    def initialize(tenant:, refresh_token:)
      @tenant = tenant
      @refresh_token = refresh_token
    end

    def call
      session = tenant.auth_sessions.find_by(
        refresh_token_digest: Auth::RefreshToken.digest(refresh_token)
      )

      raise Error, "Sessão não encontrada" unless session

      session.revoke!
      true
    end

    private

    attr_reader :tenant, :refresh_token
  end
end
