class MedicalStaff::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_medical_staff!

  def index
    @hospitals = current_user.hospitals_as_staff

    # 現在の役割に対応する病院を設定
    if current_user.current_hospital_role&.role&.is_medical_staff?
      @hospital = current_user.current_hospital_role.hospital
    else
      @hospital = @hospitals.first
    end
  end

  private

  def authorize_medical_staff!
    unless current_user.medical_staff?
      redirect_to root_path, alert: '医療従事者のみアクセスできます。'
    end
  end
end