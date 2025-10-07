class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @available_roles = current_user.available_roles
    
    # 複数の役割を持っている場合、ダッシュボードを表示
    if current_user.has_multiple_roles?
      # ダッシュボード画面を表示
    elsif current_user.current_role_medical_staff?
      redirect_to medical_staff_root_path
    else
      redirect_to blood_pressure_records_path
    end
  end

  def switch_role
    role_id = params[:role_id]
    
    if role_id.present? && current_user.available_roles.exists?(id: role_id)
      current_user.switch_to_role!(role_id)
      role = Role.find(role_id)
      flash[:notice] = "役割を「#{role.name}」に切り替えました。"
      
      # 切り替え後の画面にリダイレクト
      if role.is_medical_staff?
        redirect_to medical_staff_root_path
      else
        redirect_to blood_pressure_records_path
      end
    else
      flash[:alert] = '役割を切り替えることができません。'
      redirect_to root_path
    end
  end
end