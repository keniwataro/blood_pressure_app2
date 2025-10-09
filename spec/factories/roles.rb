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
    name { "MyString" }
    is_medical_staff { false }
    description { "MyString" }
  end
end
