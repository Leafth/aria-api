require "digest"

module Auth
  class RefreshToken
    def self.generate_token
      SecureRandom.hex(64)
    end

    def self.digest(token)
      Digest::SHA256.hexdigest(token)
    end
  end
end
