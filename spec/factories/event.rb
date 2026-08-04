FactoryBot.define do
  factory :event do
    cow
    tenant { cow.tenant }

    event_type { "inactivation" }
    occurred_at { Time.current }
    data { {} }
  end
end
