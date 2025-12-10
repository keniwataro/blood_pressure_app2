# == Schema Information
#
# Table name: roles
#
#  id               :bigint           not null, primary key
#  description      :string
#  is_hospital_role :boolean          default(TRUE), not null
#  is_medical_staff :boolean          default(FALSE), not null
#  name             :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_roles_on_name  (name) UNIQUE
#
FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "役割#{n}" }
    description { "役割の説明" }
    is_hospital_role { true }

    trait :patient do
      sequence(:name) { |n| "患者#{n}" }
      is_medical_staff { false }
      description { "血圧管理を受ける患者" }
    end

    trait :doctor do
      sequence(:name) { |n| "医師#{n}" }
      is_medical_staff { true }
      description { "患者の診断・治療を行う医師" }
    end

    trait :nurse do
      sequence(:name) { |n| "看護師#{n}" }
      is_medical_staff { true }
      description { "患者のケアを行う看護師" }
    end

    trait :system_admin do
      sequence(:name) { |n| "システム管理者#{n}" }
      is_medical_staff { false }
      is_hospital_role { false }
      description { "システム全体を管理する管理者" }
    end

    trait :medical_staff do
      is_medical_staff { true }
    end

    trait :non_medical do
      is_medical_staff { false }
    end
  end
end
