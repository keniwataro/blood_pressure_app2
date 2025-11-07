require 'rails_helper'

RSpec.describe MedicalStaff::StaffHelper, type: :helper do
  describe '#staff_role_badge' do
    let(:medical_staff) { create(:user, :medical_staff) }
    let(:non_medical_staff) { create(:user, :patient) }

    it 'returns success badge for medical staff' do
      result = helper.staff_role_badge(medical_staff)
      expect(result).to include('badge-success')
    end

    it 'returns warning badge for non-medical staff' do
      result = helper.staff_role_badge(non_medical_staff)
      expect(result).to include('badge-warning')
      expect(result).to include('医療従事者以外')
    end
  end

  describe '#staff_permission_badge' do
    let(:administrator) { create(:user, :administrator) }
    let(:general_staff) { create(:user, :medical_staff) }

    it 'returns danger badge for administrator' do
      allow(helper).to receive(:current_user).and_return(administrator)
      result = helper.staff_permission_badge(administrator)
      expect(result).to include('badge-danger')
      expect(result).to include('管理者')
    end

    it 'returns info badge for general staff' do
      allow(helper).to receive(:current_user).and_return(general_staff)
      result = helper.staff_permission_badge(general_staff)
      expect(result).to include('badge-info')
      expect(result).to include('一般')
    end
  end

  describe '#staff_action_links' do
    let(:staff) { create(:user, :medical_staff) }

    it 'returns action links' do
      result = helper.staff_action_links(staff)
      expect(result).to include('btn-group')
    end

    it 'includes detail link' do
      result = helper.staff_action_links(staff)
      expect(result).to include('詳細')
      expect(result).to include('/medical_staff/staff/')
    end

    it 'includes edit link' do
      result = helper.staff_action_links(staff)
      expect(result).to include('編集')
      expect(result).to include('/edit')
    end
  end
end
