module Auth
  class Login
    class Error < StandardError; end

    def initialize(tenant:, email:, password:, ip_address:, user_agent:)
      @tenant = tenant
      @email = email.to_s.strip.downcase
      @password = password.to_s
      @ip_address = ip_address
      @user_agent = user_agent
    end

    def call
      user = tenant.users.find_by(email: email)
      raise Error, "Tenant inválido" unless tenant

      raise Error, "Credenciais inválidas" unless user
      raise Error, "Usuário inativo" unless user.active?
      raise Error, "Credenciais inválidas" unless user.valid_password?(password)

      refresh_token = Auth::RefreshToken.generate_token

      session = AuthSession.create!(
        user: user,
        tenant: tenant,
        refresh_token_digest: Auth::RefreshToken.digest(refresh_token),
        expires_at: Rails.configuration.x.auth.refresh_token_expiration.from_now,
        ip_address: ip_address,
        user_agent: user_agent
      )

      user.update!(last_sign_in_at: Time.current)

      access_token = Auth::AccessToken.encode(
        user: user,
        tenant: tenant,
        session: session
      )

      {
        user: user,
        access_token: access_token,
        refresh_token: refresh_token,
        session: session
      }
    end

    private

    attr_reader :tenant, :email, :password, :ip_address, :user_agent
  end
end
