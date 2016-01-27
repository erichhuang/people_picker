FactoryGirl.define do
  factory :user do
    uid { "#{Faker::Name.first_name[0]}#{Faker::Name.last_name}#{Faker::Number.number(3)}" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name}
    email { Faker::Internet.email }
    is_real { false }
  end

  trait :real do
    is_real { true }
  end

  trait :brodhead do
    uid {"brodhead"}
    first_name {"Richard"}
    last_name {"Brodhead"}
    email {"president@duke.edu"}
    is_real {true}
  end
end
