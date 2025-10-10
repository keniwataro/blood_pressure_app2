class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_system_admin!

  layout 'admin'
  
  private
  
  def authorize_system_admin!
    unless current_user.system_admin?
      flash[:alert] = 'システム管理者としてログインしてください。'

      # 適切なページにリダイレクト
      if current_user.current_role_medical_staff?
        redirect_to medical_staff_root_path
      else
        redirect_to blood_pressure_records_path
      end
    end
  end
  
  def system_hospital
    @system_hospital ||= Hospital.find(1)
  end
  helper_method :system_hospital
end
