require 'rails_helper'

RSpec.describe MedicalStaff::PatientsHelper, type: :helper do
  describe '#patient_status_badge' do
    let(:patient) { create(:user, :patient).reload }

    it 'returns primary badge for patient' do
      result = helper.patient_status_badge(patient)
      expect(result).to include('badge-primary')
      expect(result).to include('患者')
    end

    it 'returns secondary badge for non-patient' do
      allow(patient).to receive(:current_role).and_return(nil)
      result = helper.patient_status_badge(patient)
      expect(result).to include('badge-secondary')
      expect(result).to include('未設定')
    end
  end

  describe '#patient_action_links' do
    let(:patient) { create(:user, :patient) }

    it 'returns action links' do
      result = helper.patient_action_links(patient)
      expect(result).to include('btn-group')
    end

    it 'includes detail link' do
      result = helper.patient_action_links(patient)
      expect(result).to include('詳細')
      expect(result).to include('/medical_staff/patients/')
    end

    it 'includes edit link' do
      result = helper.patient_action_links(patient)
      expect(result).to include('編集')
      expect(result).to include('/edit')
    end
  end
end
