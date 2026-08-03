FactoryBot.define do
  factory :tenant do
    sequence(:name) { |number| "Fazenda #{number}" }
    sequence(:slug) { |number| "fazenda-#{number}" }
    status { :active }

    trait :inactive do
      status { :inactive }
    end
  end
end
