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
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'is invalid without name' do
      user = build(:user, name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include('を入力してください')
    end

    it 'is invalid with duplicate user_id' do
      existing_user = create(:user)
      user = build(:user, user_id: existing_user.user_id)
      expect(user).not_to be_valid
    end

    it 'is invalid with duplicate email' do
      existing_user = create(:user)
      user = build(:user, email: existing_user.email)
      expect(user).not_to be_valid
    end

    it 'is valid with email' do
      user = build(:user, email: "test@example.com")
      expect(user).to be_valid
    end

    it 'validates user_id format' do
      user = build(:user, user_id: 'abc123')
      expect(user).not_to be_valid
      expect(user.errors[:user_id]).to include('は数字のみで入力してください')
    end

    it 'validates name length' do
      user = build(:user, name: 'a' * 51)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include('は50文字以内で入力してください')
    end
  end

  describe 'associations' do
    it 'has many blood_pressure_records' do
      association = described_class.reflect_on_association(:blood_pressure_records)
      expect(association.macro).to eq :has_many
      expect(association.options[:dependent]).to eq :destroy
    end

    it 'has many user_hospital_roles' do
      association = described_class.reflect_on_association(:user_hospital_roles)
      expect(association.macro).to eq :has_many
      expect(association.options[:dependent]).to eq :destroy
    end

    it 'belongs to current_hospital_role' do
      association = described_class.reflect_on_association(:current_hospital_role)
      expect(association.macro).to eq :belongs_to
      expect(association.options[:optional]).to eq true
    end
  end

  describe 'methods' do
    describe '#medical_staff?' do
      it 'returns true for medical staff' do
        user = create(:user, :medical_staff)
        expect(user.medical_staff?).to be true
      end

      it 'returns false for patient' do
        user = create(:user, :patient)
        expect(user.medical_staff?).to be false
      end
    end

    describe '#patient?' do
      it 'returns true for patient' do
        user = create(:user, :patient)
        expect(user.patient?).to be true
      end

      it 'returns false for medical staff without patient role' do
        # 純粋な医療従事者（患者ロールを持たない）ユーザーを作成
        user = create(:user)
        hospital = create(:hospital)
        doctor_role = Role.find_by(name: "医師") || create(:role, :doctor)

        create(:user_hospital_role, user: user, hospital: hospital, role: doctor_role)
        user.update_column(:current_hospital_role_id, user.user_hospital_roles.first.id)

        expect(user.patient?).to be false
      end
    end

    describe '#administrator?' do
      it 'returns true for administrator' do
        user = create(:user, :administrator)
        expect(user.administrator?).to be true
      end

      it 'returns false for general user' do
        user = create(:user, :medical_staff)
        expect(user.administrator?).to be false
      end
    end

    describe '#current_role_medical_staff?' do
      it 'returns true when current role is medical staff' do
        user = create(:user, :medical_staff)
        expect(user.current_role_medical_staff?).to be true
      end

      it 'returns false when current role is patient' do
        user = create(:user, :patient)
        expect(user.current_role_patient?).to be true
      end
    end
  end

  describe 'callbacks' do
    it 'generates user_id before validation on create' do
      user = build(:user, user_id: nil)
      user.valid?
      expect(user.user_id).to match(/\A\d{7}\z/)
    end

    it 'does not change user_id when already set' do
      user = build(:user, user_id: '1234567')
      original_user_id = user.user_id
      user.valid?
      expect(user.user_id).to eq original_user_id
    end
  end

  describe 'Devise' do
    it 'is database authenticatable' do
      expect(described_class.devise_modules).to include(:database_authenticatable)
    end

    it 'is recoverable' do
      expect(described_class.devise_modules).to include(:recoverable)
    end

    it 'is rememberable' do
      expect(described_class.devise_modules).to include(:rememberable)
    end

    it 'is validatable' do
      expect(described_class.devise_modules).to include(:validatable)
    end
  end
end
