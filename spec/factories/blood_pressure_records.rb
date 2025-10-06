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
    user { nil }
    systolic_pressure { 1 }
    diastolic_pressure { 1 }
    pulse_rate { 1 }
    measured_at { "2025-09-26 07:17:32" }
    memo { "MyText" }
  end
end
