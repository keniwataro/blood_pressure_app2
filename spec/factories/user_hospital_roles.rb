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
FactoryBot.define do
  factory :user_hospital_role do
    user { nil }
    hospital { nil }
    role { nil }
  end
end
