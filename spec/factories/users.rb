# == Schema Information
#
# Table name: users
#
#  id                       :bigint           not null, primary key
#  email                    :string           default(""), not null
#  encrypted_password       :string           default(""), not null
#  name                     :string
#  remember_created_at      :datetime
#  reset_password_sent_at   :datetime
#  reset_password_token     :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  current_hospital_role_id :bigint
#  user_id                  :string
#
# Indexes
#
#  index_users_on_current_hospital_role_id  (current_hospital_role_id)
#  index_users_on_email                     (email) UNIQUE
#  index_users_on_reset_password_token      (reset_password_token) UNIQUE
#  index_users_on_user_id                   (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_current_hospital_role_id  (current_hospital_role_id => user_hospital_roles.id)
#
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }

    # user_idはbefore_validationで自動生成されるのでここでは設定しない

    # メールアドレスはオプションなので、email_required?をfalseにしている

    trait :patient do
      after(:create) do |user|
        hospital = create(:hospital)
        # 既存の「患者」Roleを探すか、新しく作成
        patient_role = Role.find_by(name: "患者") || create(:role, :patient)
        user_hospital_role = create(:user_hospital_role, user: user, hospital: hospital, role: patient_role)
        # current_hospital_role_idを設定
        user.update_column(:current_hospital_role_id, user_hospital_role.id)
      end
    end

    trait :medical_staff do
      after(:create) do |user|
        hospital = create(:hospital)
        # 既存の「医師」Roleを探すか、新しく作成
        doctor_role = Role.find_by(name: "医師") || create(:role, :doctor)
        user_hospital_role = create(:user_hospital_role, user: user, hospital: hospital, role: doctor_role)
        user.update_column(:current_hospital_role_id, user_hospital_role.id)
      end
    end

    trait :administrator do
      after(:create) do |user|
        hospital = create(:hospital)
        # 既存の「医師」Roleを探すか、新しく作成
        doctor_role = Role.find_by(name: "医師") || create(:role, :doctor)
        user_hospital_role = create(:user_hospital_role, :administrator, user: user, hospital: hospital, role: doctor_role)
        user.update_column(:current_hospital_role_id, user_hospital_role.id)
      end
    end

    trait :system_admin do
      after(:create) do |user|
        system_hospital = create(:hospital, :system)
        # 既存の「システム管理者」Roleを探すか、新しく作成
        system_admin_role = Role.find_by(name: "システム管理者") || create(:role, :system_admin)
        user_hospital_role = create(:user_hospital_role, user: user, hospital: system_hospital, role: system_admin_role)
        user.update_column(:current_hospital_role_id, user_hospital_role.id)
      end
    end
  end
end
