class MedicalStaff::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_medical_staff!

  def index
    @hospitals = current_user.hospitals_as_staff
    @hospital = @hospitals.first # 最初の病院を選択（複数病院対応は後で）
  end

  private

  def authorize_medical_staff!
    unless current_user.medical_staff?
      redirect_to root_path, alert: '医療従事者のみアクセスできます。'
    end
  end
end