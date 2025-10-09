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
class Role < ApplicationRecord
  # アソシエーション
  has_many :user_hospital_roles, dependent: :destroy
  has_many :users, through: :user_hospital_roles
  has_many :hospitals, through: :user_hospital_roles
  
  # バリデーション
  validates :name, presence: true, uniqueness: true
  validates :is_medical_staff, inclusion: { in: [true, false] }
  
  # スコープ
  scope :medical_staff, -> { where(is_medical_staff: true) }
  scope :patients, -> { where(is_medical_staff: false) }
end
