require 'rails_helper'

RSpec.describe Hospital, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      hospital = build(:hospital)
      expect(hospital).to be_valid
    end

    describe 'name' do
      it 'is invalid without name' do
        hospital = build(:hospital, name: nil)
        expect(hospital).not_to be_valid
        expect(hospital.errors[:name]).to include('を入力してください')
      end

      it 'is invalid with name longer than 100 characters' do
        hospital = build(:hospital, name: 'a' * 101)
        expect(hospital).not_to be_valid
        expect(hospital.errors[:name]).to include('は100文字以内で入力してください')
      end

      it 'is valid with name exactly 100 characters' do
        hospital = build(:hospital, name: 'a' * 100)
        expect(hospital).to be_valid
      end
    end

    describe 'address' do
      it 'is invalid without address' do
        hospital = build(:hospital, address: nil)
        expect(hospital).not_to be_valid
        expect(hospital.errors[:address]).to include('を入力してください')
      end

      it 'is invalid with address longer than 255 characters' do
        hospital = build(:hospital, address: 'a' * 256)
        expect(hospital).not_to be_valid
        expect(hospital.errors[:address]).to include('は255文字以内で入力してください')
      end

      it 'is valid with address exactly 255 characters' do
        hospital = build(:hospital, address: 'a' * 255)
        expect(hospital).to be_valid
      end
    end

    describe 'phone_number' do
      it 'is valid with valid phone number' do
        hospital = build(:hospital, phone_number: '03-1234-5678')
        expect(hospital).to be_valid
      end

      it 'is valid without phone number' do
        hospital = build(:hospital, phone_number: nil)
        expect(hospital).to be_valid
      end

      it 'is invalid with invalid phone number format' do
        hospital = build(:hospital, phone_number: 'invalid-phone')
        expect(hospital).not_to be_valid
        expect(hospital.errors[:phone_number]).to include('は有効な電話番号を入力してください')
      end
    end

    describe 'website' do
      it 'is valid with valid website URL' do
        hospital = build(:hospital, website: 'https://example.com')
        expect(hospital).to be_valid
      end

      it 'is valid without website' do
        hospital = build(:hospital, website: nil)
        expect(hospital).to be_valid
      end

      it 'is invalid with invalid website URL' do
        hospital = build(:hospital, website: 'invalid-url')
        expect(hospital).not_to be_valid
        expect(hospital.errors[:website]).to include('は有効なURLを入力してください')
      end
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

    it 'has many roles through user_hospital_roles' do
      association = described_class.reflect_on_association(:roles)
      expect(association.macro).to eq :has_many
      expect(association.options[:through]).to eq :user_hospital_roles
    end
  end

  describe 'scopes' do
    describe '.with_name' do
      let!(:hospital1) { create(:hospital, name: '東京病院') }
      let!(:hospital2) { create(:hospital, name: '大阪病院') }
      let!(:hospital3) { create(:hospital, name: '東京クリニック') }

      it 'returns hospitals with matching name' do
        expect(described_class.with_name('東京')).to include(hospital1, hospital3)
        expect(described_class.with_name('東京')).not_to include(hospital2)
      end
    end

    describe '.excluding_system_admin' do
      let!(:system_hospital) { create(:hospital, :system) }
      let!(:regular_hospital) { create(:hospital) }

      it 'excludes system admin hospital' do
        expect(described_class.excluding_system_admin).to include(regular_hospital)
        expect(described_class.excluding_system_admin).not_to include(system_hospital)
      end
    end

    describe '.including_system_admin' do
      let!(:system_hospital) { create(:hospital, :system) }
      let!(:regular_hospital) { create(:hospital) }

      it 'includes only system admin hospital' do
        expect(described_class.including_system_admin).to include(system_hospital)
        expect(described_class.including_system_admin).not_to include(regular_hospital)
      end
    end
  end

  describe 'methods' do
    describe '#medical_staff' do
      let(:hospital) { create(:hospital) }
      let(:medical_staff) { create(:user, :medical_staff) }
      let(:patient) { create(:user, :patient) }

      before do
        # 医療従事者をこの病院に割り当て
        create(:user_hospital_role, user: medical_staff, hospital: hospital, role: medical_staff.current_role)
        # 患者をこの病院に割り当て
        create(:user_hospital_role, user: patient, hospital: hospital, role: patient.current_role)
      end

      it 'returns only medical staff users' do
        expect(hospital.medical_staff).to include(medical_staff)
        expect(hospital.medical_staff).not_to include(patient)
      end
    end

    describe '#patients' do
      let(:hospital) { create(:hospital) }
      let(:medical_staff) { create(:user, :medical_staff) }
      let(:patient) { create(:user, :patient) }

      before do
        # 医療従事者をこの病院に割り当て
        create(:user_hospital_role, user: medical_staff, hospital: hospital, role: medical_staff.current_role)
        # 患者をこの病院に割り当て
        create(:user_hospital_role, user: patient, hospital: hospital, role: patient.current_role)
      end

      it 'returns only patient users' do
        expect(hospital.patients).to include(patient)
        expect(hospital.patients).not_to include(medical_staff)
      end
    end
  end
end

