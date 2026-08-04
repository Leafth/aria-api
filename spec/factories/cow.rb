FactoryBot.define do
  factory :cow do
    tenant

    breed do
      association(:breed, tenant: tenant)
    end

    sequence(:name) { |number| "Matriz #{number}" }
    sequence(:ear_tag) { |number| format("%03d", number) }

    birth_date { Date.new(2023, 1, 1) }
    weight { 180 }
    phase { :calf }
    reproductive_status { :open }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
