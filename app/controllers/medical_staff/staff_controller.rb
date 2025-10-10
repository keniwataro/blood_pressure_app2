class MedicalStaff::StaffController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_medical_staff!
  before_action :set_hospital
  before_action :authorize_administrator!, only: [:new, :confirm_new, :create, :edit, :confirm_edit, :confirm_with_role, :confirm_reassignment, :update, :destroy]
  before_action :set_staff_member, only: [:show, :edit, :confirm_edit, :confirm_with_role, :confirm_reassignment, :update, :destroy]

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
    @roles = Role.all # 全ての役割（患者も含む）
  end

  def confirm_new
    @staff_member = User.new(staff_params)
    @roles = Role.all
    @selected_role_ids = params[:role_ids]&.reject(&:blank?)&.map(&:to_i) || []
    @permission_level = params[:user][:permission_level] || 'general'
    
    # 役割が1つも選択されていない場合はエラー
    if @selected_role_ids.empty?
      @staff_member.errors.add(:base, '役割を少なくとも1つ選択してください')
      flash.now[:alert] = '入力内容に誤りがあります。下記のエラーを確認してください。'
      render :new, status: :unprocessable_entity
      return
    end
    
    # 医療従事者の役割が1つも選択されていない場合はエラー
    selected_roles = @roles.where(id: @selected_role_ids)
    has_medical_staff_role = selected_roles.any?(&:is_medical_staff?)
    
    unless has_medical_staff_role
      @staff_member.errors.add(:base, '医療従事者の役割を少なくとも1つ選択してください')
      flash.now[:alert] = '入力内容に誤りがあります。下記のエラーを確認してください。'
      render :new, status: :unprocessable_entity
      return
    end
    
    if @staff_member.valid?
      render :confirm_new
    else
      # エラー時も@rolesを設定して入力画面に戻る
      flash.now[:alert] = '入力内容に誤りがあります。下記のエラーを確認してください。'
      render :new, status: :unprocessable_entity
    end
  end

  def create
    @staff_member = User.new(staff_params)
    @roles = Role.all # 全ての役割（患者も含む）
    permission_level = params[:user][:permission_level] || 'general'

    # 選択された役割を全て登録
    if params[:role_ids].present?
      params[:role_ids].reject(&:blank?).each do |role_id|
        role = Role.find(role_id)
        # 患者の役割にはpermission_levelを設定しない
        if role.is_medical_staff?
          UserHospitalRole.create!(
            user: @staff_member,
            hospital: @hospital,
            role_id: role_id,
            permission_level: permission_level
          )
        else
          UserHospitalRole.create!(
            user: @staff_member,
            hospital: @hospital,
            role_id: role_id
          )
        end
      end
      # 最初のuser_hospital_roleをcurrent_hospital_roleに設定
      first_user_hospital_role = @staff_member.user_hospital_roles.where(hospital_id: @hospital.id).first
      @staff_member.current_hospital_role_id = first_user_hospital_role.id if first_user_hospital_role
    end

    if @staff_member.save
      redirect_to medical_staff_staff_path(@staff_member), notice: 'スタッフを登録しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @roles = Role.all # 全ての役割（患者も含む）
    @staff_roles = @staff_member.user_hospital_roles
      .where(hospital_id: @hospital.id)
    @current_role_ids = @staff_roles.pluck(:role_id)
    # 医療従事者の役割から権限レベルを取得
    @current_permission_level = @staff_roles.joins(:role).where(roles: { is_medical_staff: true }).first&.permission_level
  end

  def confirm_edit
    # current_hospital_roleを保持してから属性を更新
    original_current_hospital_role = @staff_member.current_hospital_role
    @staff_member.assign_attributes(staff_update_params)
    @staff_member.current_hospital_role_id = original_current_hospital_role&.id
    
    @roles = Role.all
    @selected_role_ids = params[:role_ids]&.reject(&:blank?)&.map(&:to_i) || []
    @permission_level = params[:user][:permission_level] || 'general'
    
    # 役割が1つも選択されていない場合はエラー
    if @selected_role_ids.empty?
      @staff_member.errors.add(:base, '役割を少なくとも1つ選択してください')
      flash.now[:alert] = '入力内容に誤りがあります。下記のエラーを確認してください。'
      @staff_roles = @staff_member.user_hospital_roles.where(hospital_id: @hospital.id)
      @current_role_ids = @staff_roles.pluck(:role_id)
      @current_permission_level = @staff_roles.joins(:role).where(roles: { is_medical_staff: true }).first&.permission_level
      render :edit, status: :unprocessable_entity
      return
    end
    
    # 医療従事者の役割がなくなるかチェック
    selected_roles = @roles.where(id: @selected_role_ids)
    has_medical_staff_role = selected_roles.any?(&:is_medical_staff?)
    current_has_medical_staff_role = @staff_member.user_hospital_roles
                                        .joins(:role)
                                        .where(hospital_id: @hospital.id, roles: { is_medical_staff: true })
                                        .exists?
    
    # 医療従事者の役割がなくなり、担当患者がいる場合は担当者変更画面へ
    if current_has_medical_staff_role && !has_medical_staff_role
      all_assigned_patients = @staff_member.assigned_patients_at(@hospital)
      
      # 他に担当スタッフがいない患者のみを抽出
      @assigned_patients = []
      @patient_available_staff = {}
      
      all_assigned_patients.each do |patient|
        # 現在の担当スタッフのIDを取得（引き継ぎ元のスタッフを除く）
        other_staff_ids = patient.assigned_staff_at(@hospital).where.not(id: @staff_member.id).pluck(:id)
        
        # 他に担当スタッフがいない場合のみ、引き継ぎが必要
        if other_staff_ids.empty?
          @assigned_patients << patient
          # 引き継ぎ元のスタッフを除外したスタッフリストを作成
          @patient_available_staff[patient.id] = @hospital.medical_staff
                                                           .where.not(id: @staff_member.id)
                                                           .order(:name)
        end
      end
      
      # 引き継ぎが必要な患者がいる場合のみ、引き継ぎ画面を表示
      if @assigned_patients.any?
        render :reassign_patients
        return
      end
    end
    
    # 現在の役割が削除される場合は、役割選択画面へ
    if original_current_hospital_role && @selected_role_ids.present? && !@selected_role_ids.include?(original_current_hospital_role.role_id)
      @available_roles = @roles.where(id: @selected_role_ids)
      render :select_current_role
      return
    end
    
    if @staff_member.valid?
      render :confirm_edit
    else
      @staff_roles = @staff_member.user_hospital_roles.where(hospital_id: @hospital.id)
      @current_role_ids = @staff_roles.pluck(:role_id)
      @current_permission_level = @staff_roles.joins(:role).where(roles: { is_medical_staff: true }).first&.permission_level
      render :edit, status: :unprocessable_entity
    end
  end
  
  def confirm_with_role
    # 選択された新しいcurrent_role_idを取得（RoleのID）
    new_current_role_id = params[:new_current_role_id].to_i

    # 対応するUserHospitalRoleを取得
    new_user_hospital_role = @staff_member.user_hospital_roles.where(hospital_id: @hospital.id, role_id: new_current_role_id).first

    @staff_member.assign_attributes(staff_update_params)
    @staff_member.current_hospital_role_id = new_user_hospital_role&.id

    @roles = Role.all
    @selected_role_ids = params[:role_ids]&.reject(&:blank?)&.map(&:to_i) || []
    @permission_level = params[:user][:permission_level] || 'general'

    # 新しいcurrent_role_idが選択された役割の中に含まれているかチェック
    selected_user_hospital_roles = @staff_member.user_hospital_roles.where(hospital_id: @hospital.id, role_id: @selected_role_ids)
    unless new_user_hospital_role && selected_user_hospital_roles.exists?(id: new_user_hospital_role.id)
      flash.now[:alert] = '選択された現在の役割が、設定する役割に含まれていません。'
      @available_user_hospital_roles = selected_user_hospital_roles
      @available_roles = @roles.where(id: @selected_role_ids)
      render :select_current_role, status: :unprocessable_entity
      return
    end
    
    # 確認画面では基本的なバリデーションのみ実行（current_role_idのバリデーションはスキップ）
    @staff_member.valid?
    # current_hospital_role_idのエラーを削除（確認画面では役割が未更新のため）
    @staff_member.errors.delete(:current_hospital_role_id)
    
    if @staff_member.errors.empty?
      render :confirm_edit
    else
      @staff_roles = @staff_member.user_hospital_roles.where(hospital_id: @hospital.id)
      @current_role_ids = @staff_roles.pluck(:role_id)
      @current_permission_level = @staff_roles.joins(:role).where(roles: { is_medical_staff: true }).first&.permission_level
      render :edit, status: :unprocessable_entity
    end
  end
  
  def confirm_reassignment
    # 担当者変更後に確認画面へ
    @staff_member.assign_attributes(staff_update_params)
    
    @roles = Role.all
    @selected_role_ids = params[:role_ids]&.reject(&:blank?)&.map(&:to_i) || []
    @permission_level = params[:user][:permission_level] || 'general'
    @patient_reassignments = params[:patient_reassignments] || {}
    
    # 現在の役割が削除される場合は、役割選択画面へ
    original_current_hospital_role = @staff_member.current_hospital_role
    if original_current_hospital_role && @selected_role_ids.present? && !@selected_role_ids.include?(original_current_hospital_role.role_id)
      @available_roles = @roles.where(id: @selected_role_ids)
      render :select_current_role
      return
    end
    
    # current_hospital_role_idを保持
    @staff_member.current_hospital_role_id = original_current_hospital_role.id
    
    # 確認画面では基本的なバリデーションのみ実行
    @staff_member.valid?
    @staff_member.errors.delete(:current_hospital_role_id)
    
    if @staff_member.errors.empty?
      render :confirm_edit
    else
      @staff_roles = @staff_member.user_hospital_roles.where(hospital_id: @hospital.id)
      @current_role_ids = @staff_roles.pluck(:role_id)
      @current_permission_level = @staff_roles.joins(:role).where(roles: { is_medical_staff: true }).first&.permission_level
      render :edit, status: :unprocessable_entity
    end
  end

  def update
    # 担当患者の再割り当て処理
    if params[:patient_reassignments].present?
      params[:patient_reassignments].each do |patient_id, new_staff_id|
        next if new_staff_id.blank?
        
        patient = @hospital.patients.find(patient_id)
        # 現在のスタッフの担当を解除
        PatientStaffAssignment.where(patient: patient, staff: @staff_member, hospital: @hospital).destroy_all
        
        # 新しいスタッフに担当を割り当て（既に担当でない場合のみ）
        unless PatientStaffAssignment.exists?(patient: patient, staff_id: new_staff_id, hospital: @hospital)
          PatientStaffAssignment.create(patient: patient, staff_id: new_staff_id, hospital: @hospital)
        end
      end
    end
    
    if @staff_member.update(staff_update_params)
      # 役割と権限レベルの更新
      current_roles = @staff_member.user_hospital_roles
        .where(hospital_id: @hospital.id)
      
      new_role_ids = params[:role_ids].present? ? params[:role_ids].reject(&:blank?).map(&:to_i) : []
      current_role_ids = current_roles.pluck(:role_id)
      permission_level = params[:user][:permission_level] || 'general'
      
      # 削除する役割
      role_ids_to_remove = current_role_ids - new_role_ids

      # 削除されるUserHospitalRoleのIDを取得
      user_hospital_roles_to_remove = current_roles.where(role_id: role_ids_to_remove)
      user_hospital_role_ids_to_remove = user_hospital_roles_to_remove.pluck(:id)

      # current_hospital_role_idが削除される場合、変更する
      if @staff_member.current_hospital_role_id && user_hospital_role_ids_to_remove.include?(@staff_member.current_hospital_role_id)
        # 残りの役割から新しいcurrent_hospital_role_idを選択
        remaining_roles = current_roles.where.not(id: user_hospital_role_ids_to_remove)
        if remaining_roles.exists?
          new_current_role = remaining_roles.first
          @staff_member.update_column(:current_hospital_role_id, new_current_role.id)
        else
          # 役割がなくなる場合はnilに設定
          @staff_member.update_column(:current_hospital_role_id, nil)
        end
      end

      # 役割を削除
      user_hospital_roles_to_remove.destroy_all
      
      # 追加する役割
      role_ids_to_add = new_role_ids - current_role_ids
      role_ids_to_add.each do |role_id|
        role = Role.find(role_id)
        # 患者の役割にはpermission_levelを設定しない
        if role.is_medical_staff?
          UserHospitalRole.create!(
            user: @staff_member,
            hospital: @hospital,
            role_id: role_id,
            permission_level: permission_level
          )
        else
          UserHospitalRole.create!(
            user: @staff_member,
            hospital: @hospital,
            role_id: role_id
          )
        end
      end
      
      # 既存の医療従事者役割の権限レベルを更新
      medical_staff_role_ids = Role.medical_staff.pluck(:id)
      existing_medical_staff_role_ids = (new_role_ids & current_role_ids) & medical_staff_role_ids
      current_roles.where(role_id: existing_medical_staff_role_ids).update_all(permission_level: UserHospitalRole.permission_levels[permission_level])
      
      # 更新後の役割をチェック
      updated_roles = @staff_member.user_hospital_roles.where(hospital_id: @hospital.id).includes(:role)
      has_medical_staff_role = updated_roles.any? { |uhr| uhr.role.is_medical_staff? }
      
      # 患者の役割のみになった場合は患者詳細画面へリダイレクト
      if !has_medical_staff_role && updated_roles.any?
        redirect_to medical_staff_patient_path(@staff_member), notice: 'スタッフ情報を更新しました。患者としての情報は患者詳細画面で確認できます。'
      else
        redirect_to medical_staff_staff_path(@staff_member), notice: 'スタッフ情報を更新しました。'
      end
    else
      @roles = Role.all
      @staff_roles = @staff_member.user_hospital_roles
        .where(hospital_id: @hospital.id)
      @current_role_ids = @staff_roles.pluck(:role_id)
      @current_permission_level = @staff_roles.joins(:role).where(roles: { is_medical_staff: true }).first&.permission_level
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # current_hospital_role_idが削除されるuser_hospital_rolesを参照している場合、nilに設定
    @staff_member.update_column(:current_hospital_role_id, nil)
    @staff_member.destroy
    redirect_to medical_staff_staff_index_path, notice: "#{@staff_member.name} を削除しました。"
  end

  private

  def authorize_medical_staff!
    unless current_user.medical_staff?
      redirect_to root_path, alert: '医療従事者のみアクセスできます。'
    end
  end

  def set_hospital
    if current_user.current_hospital_role&.role&.is_medical_staff?
      @hospital = current_user.current_hospital_role.hospital
    else
      @hospital = current_user.hospitals_as_staff.first
    end

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