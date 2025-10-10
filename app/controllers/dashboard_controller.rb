class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # システム管理者の場合は管理画面にリダイレクト
    if current_user.system_admin?
      redirect_to admin_root_path
      return
    end
    
    # 病院ごとに役割をグループ化
    @hospital_roles = current_user.user_hospital_roles.includes(:hospital, :role).group_by do |uhr|
      uhr.hospital
    end

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
    user_hospital_role_id = params[:user_hospital_role_id]

    if user_hospital_role_id.present?
      user_hospital_role = current_user.user_hospital_roles.find_by(id: user_hospital_role_id)
      if user_hospital_role
        current_user.update_column(:current_hospital_role_id, user_hospital_role_id)
        role = user_hospital_role.role
        hospital = user_hospital_role.hospital
        flash[:notice] = "役割を「#{hospital.name}: #{role.name}」に切り替えました。"

        # 切り替え後の画面にリダイレクト
        if role.name == 'システム管理者'
          redirect_to admin_root_path
        elsif role.is_medical_staff?
          redirect_to medical_staff_root_path
        else
          redirect_to blood_pressure_records_path
        end
      else
        flash[:alert] = '役割を切り替えることができません。'
        redirect_to root_path
      end
    else
      flash[:alert] = '役割を切り替えることができません。'
      redirect_to root_path
    end
  end
end