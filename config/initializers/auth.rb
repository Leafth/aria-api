Rails.application.config.x.auth = ActiveSupport::OrderedOptions.new

Rails.application.config.x.auth.access_token_secret =
  ENV.fetch("ACCESS_TOKEN_SECRET") { Rails.application.credentials.secret_key_base }

Rails.application.config.x.auth.access_token_expiration = 15.minutes
Rails.application.config.x.auth.refresh_token_expiration = 30.days
