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
require 'rails_helper'

RSpec.describe UserHospitalRole, type: :model do
  describe 'validations' do
    let(:user) { create(:user) }
    let(:hospital) { create(:hospital) }
    let(:role) { create(:role) }

    it 'is valid with valid attributes' do
      user_hospital_role = build(:user_hospital_role, user: user, hospital: hospital, role: role)
      expect(user_hospital_role).to be_valid
    end

    describe 'user_id uniqueness' do
      let!(:existing_role) { create(:user_hospital_role, user: user, hospital: hospital, role: role) }

      it 'is invalid with duplicate user_id, hospital_id, role_id combination' do
        duplicate_role = build(:user_hospital_role, user: user, hospital: hospital, role: role)
        expect(duplicate_role).not_to be_valid
        expect(duplicate_role.errors[:user_id]).to include('は既にこの病院でこの役割を持っています')
      end

      it 'is valid with same user_id but different hospital_id' do
        different_hospital = create(:hospital)
        valid_role = build(:user_hospital_role, user: user, hospital: different_hospital, role: role)
        expect(valid_role).to be_valid
      end

      it 'is valid with same user_id and hospital_id but different role_id' do
        different_role = create(:role)
        valid_role = build(:user_hospital_role, user: user, hospital: hospital, role: different_role)
        expect(valid_role).to be_valid
      end
    end

    describe 'permission_level' do
      it 'is invalid without permission_level' do
        user_hospital_role = build(:user_hospital_role, permission_level: nil)
        expect(user_hospital_role).not_to be_valid
        expect(user_hospital_role.errors[:permission_level]).to include('を入力してください')
      end

      it 'defaults to general' do
        user_hospital_role = create(:user_hospital_role)
        expect(user_hospital_role.permission_level).to eq('general')
      end
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end

    it 'belongs to hospital' do
      association = described_class.reflect_on_association(:hospital)
      expect(association.macro).to eq :belongs_to
    end

    it 'belongs to role' do
      association = described_class.reflect_on_association(:role)
      expect(association.macro).to eq :belongs_to
    end
  end

  describe 'enums' do
    describe 'permission_level' do
      it 'defines general as 0' do
        expect(described_class.permission_levels[:general]).to eq(0)
      end

      it 'defines administrator as 1' do
        expect(described_class.permission_levels[:administrator]).to eq(1)
      end

      describe '#permission_level_general?' do
        it 'returns true for general permission' do
          role = build(:user_hospital_role, permission_level: :general)
          expect(role.permission_level_general?).to be true
        end

        it 'returns false for administrator permission' do
          role = build(:user_hospital_role, permission_level: :administrator)
          expect(role.permission_level_general?).to be false
        end
      end

      describe '#permission_level_administrator?' do
        it 'returns true for administrator permission' do
          role = build(:user_hospital_role, permission_level: :administrator)
          expect(role.permission_level_administrator?).to be true
        end

        it 'returns false for general permission' do
          role = build(:user_hospital_role, permission_level: :general)
          expect(role.permission_level_administrator?).to be false
        end
      end
    end
  end

  describe 'delegates' do
    let(:user) { create(:user) }
    let(:hospital) { create(:hospital) }
    let(:role) { create(:role) }
    let(:user_hospital_role) { create(:user_hospital_role, user: user, hospital: hospital, role: role) }

    describe '#role_name' do
      it 'delegates to role.name' do
        expect(user_hospital_role.role_name).to eq(role.name)
      end
    end

    describe '#hospital_name' do
      it 'delegates to hospital.name' do
        expect(user_hospital_role.hospital_name).to eq(hospital.name)
      end
    end

    describe '#is_medical_staff' do
      it 'delegates to role.is_medical_staff' do
        expect(user_hospital_role.is_medical_staff).to eq(role.is_medical_staff)
      end
    end
  end

  describe 'factory traits' do
    describe ':administrator' do
      it 'creates user hospital role with administrator permission' do
        role = create(:user_hospital_role, :administrator)
        expect(role.permission_level).to eq('administrator')
      end
    end

    describe ':general' do
      it 'creates user hospital role with general permission' do
        role = create(:user_hospital_role, :general)
        expect(role.permission_level).to eq('general')
      end
    end
  end
end
