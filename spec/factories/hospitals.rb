# == Schema Information
#
# Table name: hospitals
#
#  id           :bigint           not null, primary key
#  address      :text
#  name         :string
#  phone_number :string
#  website      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
FactoryBot.define do
  factory :hospital do
    sequence(:name) { |n| "病院#{n}" }
    address { Faker::Address.full_address }
    phone_number { Faker::PhoneNumber.phone_number }
    website { Faker::Internet.url }

    trait :system do
      name { "システム管理病院" }
      address { "システム用アドレス" }
      phone_number { nil }
      website { nil }
    end

    trait :with_valid_phone do
      phone_number { "03-1234-5678" }
    end

    trait :with_valid_website do
      website { "https://example.com" }
    end
  end
end
