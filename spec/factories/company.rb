FactoryBot.define do
  factory :company do
    tenant

    sequence(:name) { |number| "Empresa #{number}" }
  end
end
