# == Schema Information
#
# Table name: user_hospital_roles
#
#  id               :bigint           not null, primary key
#  permission_level :integer          default("general"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  hospital_id      :bigint           not null
#  role_id          :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_user_hospital_roles_on_hospital_id       (hospital_id)
#  index_user_hospital_roles_on_permission_level  (permission_level)
#  index_user_hospital_roles_on_role_id           (role_id)
#  index_user_hospital_roles_on_user_id           (user_id)
#  index_user_hospital_roles_unique               (user_id,hospital_id,role_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (hospital_id => hospitals.id)
#  fk_rails_...  (role_id => roles.id)
#  fk_rails_...  (user_id => users.id)
#
class UserHospitalRole < ApplicationRecord
  # アソシエーション
  belongs_to :user
  belongs_to :hospital
  belongs_to :role
  
  # 権限レベル
  enum permission_level: {
    general: 0,      # 一般
    administrator: 1 # 管理者
  }, _prefix: true
  
  # バリデーション
  validates :user_id, uniqueness: { scope: [:hospital_id, :role_id], message: "は既にこの病院でこの役割を持っています" }
  validates :permission_level, presence: true
  
  # デリゲート
  delegate :name, to: :role, prefix: true
  delegate :name, to: :hospital, prefix: true
  delegate :is_medical_staff, to: :role
end
