FactoryBot.define do
  factory :breed do
    tenant

    sequence(:name) { |number| "Raça #{number}" }
  end
end
