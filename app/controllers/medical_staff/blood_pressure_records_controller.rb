class MedicalStaff::BloodPressureRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_medical_staff!
  before_action :set_hospital
  before_action :set_patient
  before_action :set_blood_pressure_record, only: [:show]

  def index
    @blood_pressure_records = @patient.blood_pressure_records.recent
  end

  def show
  end

  private

  def authorize_medical_staff!
    unless current_user.medical_staff?
      redirect_to root_path, alert: '医療従事者のみアクセスできます。'
    end
  end

  def set_hospital
    @hospital = current_user.hospitals_as_staff.first
    unless @hospital
      redirect_to root_path, alert: '病院が登録されていません。'
    end
  end

  def set_patient
    @patient = @hospital.patients.find(params[:patient_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to medical_staff_patients_path, alert: '患者が見つかりませんでした。'
  end

  def set_blood_pressure_record
    @blood_pressure_record = @patient.blood_pressure_records.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to medical_staff_patient_blood_pressure_records_path(@patient), alert: '血圧記録が見つかりませんでした。'
  end
end