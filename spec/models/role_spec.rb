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
require 'rails_helper'

RSpec.describe Role, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      role = build(:role)
      expect(role).to be_valid
    end

    it 'is invalid without name' do
      role = build(:role, name: nil)
      expect(role).not_to be_valid
      expect(role.errors[:name]).to include('を入力してください')
    end

    it 'is invalid with duplicate name' do
      existing_role = create(:role)
      role = build(:role, name: existing_role.name)
      expect(role).not_to be_valid
    end

    it 'is valid with medical_staff values' do
      role = build(:role, is_medical_staff: true)
      expect(role).to be_valid
    end

    it 'is valid with non_medical values' do
      role = build(:role, is_medical_staff: false)
      expect(role).to be_valid
    end
  end

  describe 'associations' do
    it 'has many user_hospital_roles' do
      association = described_class.reflect_on_association(:user_hospital_roles)
      expect(association.macro).to eq :has_many
      expect(association.options[:dependent]).to eq :destroy
    end

    it 'has many users through user_hospital_roles' do
      association = described_class.reflect_on_association(:users)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :user_hospital_roles
    end

    it 'has many hospitals through user_hospital_roles' do
      association = described_class.reflect_on_association(:hospitals)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :user_hospital_roles
    end
  end

  describe 'scopes' do
    describe '.medical_staff' do
      it 'returns only medical staff roles' do
        # seedデータで作成されたRoleを使用するか、テスト用に作成
        doctor_role = described_class.find_by(name: "医師") || create(:role, :doctor)
        patient_role = described_class.find_by(name: "患者") || create(:role, :patient)

        expect(described_class.medical_staff).to include(doctor_role)
        expect(described_class.medical_staff).not_to include(patient_role)
      end
    end

    describe '.patients' do
      it 'returns only patient roles' do
        # seedデータで作成されたRoleを使用するか、テスト用に作成
        doctor_role = described_class.find_by(name: "医師") || create(:role, :doctor)
        patient_role = described_class.find_by(name: "患者") || create(:role, :patient)

        expect(described_class.patients).to include(patient_role)
        expect(described_class.patients).not_to include(doctor_role)
      end
    end
  end

  describe 'factory traits' do
    describe ':patient' do
      it 'creates a patient role' do
        role = create(:role, :patient)
        expect(role.name).to start_with('患者')
        expect(role.is_medical_staff).to be false
      end
    end

    describe ':doctor' do
      it 'creates a doctor role' do
        role = create(:role, :doctor)
        expect(role.name).to start_with('医師')
        expect(role.is_medical_staff).to be true
      end
    end

    describe ':nurse' do
      it 'creates a nurse role' do
        role = create(:role, :nurse)
        expect(role.name).to start_with('看護師')
        expect(role.is_medical_staff).to be true
      end
    end

    describe ':system_admin' do
      it 'creates a system admin role' do
        role = create(:role, :system_admin)
        expect(role.name).to start_with('システム管理者')
        expect(role.is_medical_staff).to be false
        expect(role.is_hospital_role).to be false
      end
    end
  end
end
