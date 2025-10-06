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
class BloodPressureRecord < ApplicationRecord
  belongs_to :user

  # バリデーション
  validates :systolic_pressure, presence: true, 
            numericality: { greater_than: 0, less_than: 300 }
  validates :diastolic_pressure, presence: true, 
            numericality: { greater_than: 0, less_than: 200 }
  validates :pulse_rate, presence: true, 
            numericality: { greater_than: 0, less_than: 300 }
  validates :measured_at, presence: true

  # スコープ
  scope :recent, -> { order(measured_at: :desc) }
  scope :this_month, -> { where(measured_at: 1.month.ago..Time.current) }

  # 血圧の分類を判定するメソッド
  def blood_pressure_category
    if systolic_pressure < 120 && diastolic_pressure < 80
      "正常血圧"
    elsif systolic_pressure < 130 && diastolic_pressure < 85
      "正常高値血圧"
    elsif systolic_pressure < 140 && diastolic_pressure < 90
      "軽症高血圧（Ⅰ度）"
    elsif systolic_pressure < 160 && diastolic_pressure < 100
      "中等症高血圧（Ⅱ度）"
    else
      "重症高血圧（Ⅲ度）"
    end
  end
end
