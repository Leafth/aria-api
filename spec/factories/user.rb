FactoryBot.define do
  factory :user do
    tenant

    sequence(:name) { |number| "Usuário #{number}" }
    sequence(:email) { |number| "usuario#{number}@email.com" }

    password { "@Senha123" }
    password_confirmation { "@Senha123" }
    status { :active }

    trait :inactive do
      status { :inactive }
    end
  end
end
