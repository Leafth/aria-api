module Auth
  class AccessToken
      ALGORITHM = "HS256".freeze

    def self.encode(user:, tenant:, session:)
      payload = {
        sub: user.id,
        tenant_id: tenant.id,
        session_id: session.id,
        email: user.email,
        iat: Time.current.to_i,
        exp: Rails.configuration.x.auth.access_token_expiration.from_now.to_i
      }

      JWT.encode(
        payload,
        Rails.configuration.x.auth.access_token_secret,
        ALGORITHM
      )
    end

    def self.decode(token)
      decoded_token = JWT.decode(
        token,
        Rails.configuration.x.auth.access_token_secret,
        true,
        { algorithm: ALGORITHM, verify_expiration: true }
      )

      decoded_token.first.with_indifferent_access
    end
  end
end
