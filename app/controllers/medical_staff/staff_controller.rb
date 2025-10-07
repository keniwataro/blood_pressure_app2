class MedicalStaff::StaffController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_medical_staff!
  before_action :set_hospital
  before_action :authorize_administrator!, only: [:new, :create, :edit, :update]
  before_action :set_staff_member, only: [:show, :edit, :update]

  def index
    @staff_members = @hospital.medical_staff.includes(:user_hospital_roles, :roles).order(created_at: :desc)
    @roles = Role.medical_staff
  end

  def show
    @staff_roles = @staff_member.user_hospital_roles
      .joins(:role)
      .where(hospital_id: @hospital.id, roles: { is_medical_staff: true })
      .includes(:role)
  end

  def new
    @staff_member = User.new
    @roles = Role.medical_staff
  end

  def create
    @staff_member = User.new(staff_params)
    @roles = Role.medical_staff
    role = Role.find(params[:user][:role_id])
    permission_level = params[:user][:permission_level] || 'general'
    
    if @staff_member.save
      # 医療従事者として病院に登録
      UserHospitalRole.create!(
        user: @staff_member,
        hospital: @hospital,
        role: role,
        permission_level: permission_level
      )
      redirect_to medical_staff_staff_path(@staff_member), notice: 'スタッフを登録しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @roles = Role.medical_staff
    user_hospital_role = @staff_member.user_hospital_roles
      .joins(:role)
      .where(hospital_id: @hospital.id, roles: { is_medical_staff: true })
      .first
    @current_role = user_hospital_role&.role
    @current_permission_level = user_hospital_role&.permission_level
  end

  def update
    if @staff_member.update(staff_update_params)
      # 役割と権限レベルの更新
      user_hospital_role = @staff_member.user_hospital_roles
        .where(hospital_id: @hospital.id)
        .joins(:role)
        .where(roles: { is_medical_staff: true })
        .first
      
      if user_hospital_role
        if params[:user][:role_id].present?
          role = Role.find(params[:user][:role_id])
          user_hospital_role.role = role
        end
        
        if params[:user][:permission_level].present?
          user_hospital_role.permission_level = params[:user][:permission_level]
        end
        
        user_hospital_role.save!
      end
      
      redirect_to medical_staff_staff_path(@staff_member), notice: 'スタッフ情報を更新しました。'
    else
      @roles = Role.medical_staff
      render :edit, status: :unprocessable_entity
    end
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

  def set_staff_member
    @staff_member = @hospital.medical_staff.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to medical_staff_staff_index_path, alert: 'スタッフが見つかりませんでした。'
  end

  def staff_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def staff_update_params
    params.require(:user).permit(:name, :email)
  end

  def authorize_administrator!
    unless current_user.administrator_at?(@hospital)
      redirect_to medical_staff_staff_index_path, alert: '管理者のみがスタッフの登録・編集を行えます。'
    end
  end
end