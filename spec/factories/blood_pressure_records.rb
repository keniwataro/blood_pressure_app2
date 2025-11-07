# == Schema Information
#
# Table name: blood_pressure_records
#
#  id                 :bigint           not null, primary key
#  diastolic_pressure :integer
#  measured_at        :datetime
#  memo               :text
#  pulse_rate         :integer
#  systolic_pressure  :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint           not null
#
# Indexes
#
#  index_blood_pressure_records_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :blood_pressure_record do
    association :user, :patient
    systolic_pressure { 120 }  # 正常値
    diastolic_pressure { 80 }  # 正常値
    pulse_rate { 70 }          # 正常値
    measured_at { Time.current }
    memo { Faker::Lorem.sentence }

    trait :normal do
      systolic_pressure { 118 }
      diastolic_pressure { 78 }
      pulse_rate { 72 }
    end

    trait :high_normal do
      systolic_pressure { 125 }
      diastolic_pressure { 82 }
      pulse_rate { 75 }
    end

    trait :hypertension_stage1 do
      systolic_pressure { 135 }
      diastolic_pressure { 85 }
      pulse_rate { 78 }
    end

    trait :hypertension_stage2 do
      systolic_pressure { 150 }
      diastolic_pressure { 95 }
      pulse_rate { 80 }
    end

    trait :severe_hypertension do
      systolic_pressure { 180 }
      diastolic_pressure { 110 }
      pulse_rate { 85 }
    end

    trait :low_blood_pressure do
      systolic_pressure { 90 }
      diastolic_pressure { 60 }
      pulse_rate { 65 }
    end

    trait :with_memo do
      memo { "朝食後30分で測定。落ち着いた状態で測定。" }
    end

    trait :recent do
      measured_at { 1.hour.ago }
    end

    trait :old do
      measured_at { 1.month.ago }
    end
  end
end
