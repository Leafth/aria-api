FactoryBot.define do
  factory :auth_session do
    user
    tenant { user&.tenant }

    sequence(:refresh_token_digest) do |number|
      "refresh-token-digest-#{number}"
    end

    expires_at { 1.day.from_now }
    revoked_at { nil }

    trait :revoked do
      revoked_at { Time.current }
    end

    trait :expired do
      expires_at { 1.minute.ago }
    end
  end
end
