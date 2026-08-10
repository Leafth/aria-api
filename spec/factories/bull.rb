FactoryBot.define do
  factory :bull do
    tenant

    breed do
      association(:breed, tenant: tenant)
    end

    sequence(:name) { |number| "Touro #{number}" }
    sequence(:ear_tag) { |number| format("%03d", number) }

    origin { :local }
    company { nil }

    trait :from_company do
      origin { :company }
      ear_tag { nil }

      company do
        create(:company, tenant: tenant)
      end
    end
  end
end
