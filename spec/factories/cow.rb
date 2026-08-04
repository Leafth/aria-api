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

    trait :heifer do
      phase { :heifer }
    end

    trait :young do
      phase { :young }
    end

    trait :primiparous do
      phase { :primiparous }
    end

    trait :multiparous do
      phase { :multiparous }
    end

    trait :in_heat do
      reproductive_status { :in_heat }
    end

    trait :inseminated do
      reproductive_status { :inseminated }
    end

    trait :pregnant do
      reproductive_status { :pregnant }
    end

    trait :postpartum do
      reproductive_status { :postpartum }
    end
  end
end
