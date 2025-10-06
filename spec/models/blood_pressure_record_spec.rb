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
require 'rails_helper'

RSpec.describe BloodPressureRecord, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
