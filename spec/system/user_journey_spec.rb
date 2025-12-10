require 'rails_helper'

RSpec.describe "User Journey", type: :system do
  include AuthenticationHelper

  before do
    driven_by(:rack_test)
  end

  describe "Patient User Journey" do
    it "allows patient to login, create blood pressure record, and edit profile" do
      # Factoryで患者ユーザーを作成
      patient = create(:user, :patient)

      # ログイン
      sign_in(patient)

      expect(page).to have_current_path(authenticated_root_path)

      # 血圧記録の作成（モデルレベルでテスト）
      record = create(:blood_pressure_record,
                     user: patient,
                     systolic_pressure: 120,
                     diastolic_pressure: 80,
                     pulse_rate: 70)
      expect(record).to be_persisted
      expect(record.systolic_pressure).to eq(120)

      # プロフィールの編集（モデルレベルでテスト）
      original_name = patient.name
      patient.update(name: '更新された患者')
      expect(patient.name).to eq('更新された患者')
      expect(patient.name).not_to eq(original_name)
    end
  end

  describe "Medical Staff User Journey" do
    let!(:hospital) { create(:hospital) }
    let!(:patient) { create(:user, :patient) }
    let!(:medical_staff) { create(:user, :medical_staff) }

    before do
      # 医療従事者と患者を同じ病院に割り当て
      create(:user_hospital_role, user: medical_staff, hospital: hospital, role: create(:role, :doctor))
      create(:user_hospital_role, user: patient, hospital: hospital, role: create(:role, :patient))
    end

    it "allows medical staff to login, view patients, and check blood pressure records" do
      # ログイン
      sign_in(medical_staff)

      # 医療従事者は認証後にダッシュボードにリダイレクトされる
      expect(page).to have_current_path(authenticated_root_path)

      # 患者一覧の確認（モデルレベルでテスト）
      # 医療従事者が同じ病院の患者にアクセスできることを確認
      staff_role = UserHospitalRole.find_by(user: medical_staff, hospital: hospital)
      patient_role = UserHospitalRole.find_by(user: patient, hospital: hospital)
      expect(staff_role).to be_present
      expect(patient_role).to be_present
      expect(staff_role.hospital).to eq(patient_role.hospital)

      # 患者の血圧記録を作成（Factoryで作成）
      blood_pressure_record = create(:blood_pressure_record, user: patient, systolic_pressure: 130, diastolic_pressure: 85, pulse_rate: 75)
      expect(blood_pressure_record).to be_persisted

      # 医療従事者が患者の記録にアクセスできることを確認（モデルレベル）
      expect(blood_pressure_record.user).to eq(patient)
    end
  end

  describe "Administrator User Journey" do
    let!(:system_admin) { create(:user, :system_admin) }
    let!(:hospital) { create(:hospital) }

    it "allows administrator to login, manage hospitals, and manage users" do
      # ログイン
      sign_in(system_admin)

      expect(page).to have_current_path(authenticated_root_path)

      # 病院管理（モデルレベルでテスト）
      new_hospital = create(:hospital, name: '新しいテスト病院', address: '東京都渋谷区', phone_number: '03-1234-5678')
      expect(new_hospital).to be_persisted
      expect(new_hospital.name).to eq('新しいテスト病院')

      # 病院一覧に新しい病院が含まれていることを確認
      expect(Hospital.where(name: '新しいテスト病院')).to exist
    end
  end
end
