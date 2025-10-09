class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @users = User.all.order(:name).page(params[:page]).per(20)

    # 検索機能
    if params[:search].present?
      @users = @users.where("name LIKE ? OR email LIKE ? OR user_id LIKE ?",
                           "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    # 役割フィルター
    if params[:role_id].present?
      @users = @users.joins(:user_hospital_roles).where(user_hospital_roles: { role_id: params[:role_id] }).distinct
    end

    # 病院フィルター
    if params[:hospital_id].present?
      @users = @users.joins(:user_hospital_roles).where(user_hospital_roles: { hospital_id: params[:hospital_id] }).distinct
    end

    # 患者/医療従事者/病院管理者フィルター
    if params[:user_type].present?
      if params[:user_type] == 'patient'
        # 患者のみ（医療従事者ではない役割）
        @users = @users.joins(:user_hospital_roles => :role).where.not(roles: { is_medical_staff: true }).distinct
      elsif params[:user_type] == 'medical_staff'
        # 医療従事者のみ
        @users = @users.joins(:user_hospital_roles => :role).where(roles: { is_medical_staff: true }).distinct
      elsif params[:user_type] == 'hospital_admin'
        # 病院管理者のみ（医療従事者でpermission_level = 1）
        @users = @users.joins(:user_hospital_roles => :role)
                       .where(roles: { is_medical_staff: true })
                       .where(user_hospital_roles: { permission_level: UserHospitalRole.permission_levels[:administrator] })
                       .distinct
      end
    end
  end

  def new
    @user = User.new
    @global_roles = Role.where(is_hospital_role: false) # 病院非依存の役割
    @hospital_roles = Role.where(is_hospital_role: true) # 病院毎の役割
    @medical_roles = Role.where(is_hospital_role: true, is_medical_staff: true) # 医療従事者の役割
    @roles = @medical_roles # ビューでの互換性のため
    @hospitals = Hospital.excluding_system_admin # システム管理病院を除外した病院一覧
  end

  def create
    @global_roles = Role.where(is_hospital_role: false) # 病院非依存の役割
    @hospital_roles = Role.where(is_hospital_role: true) # 病院毎の役割
    @medical_roles = Role.where(is_hospital_role: true, is_medical_staff: true) # 医療従事者の役割
    @roles = @medical_roles # ビューでの互換性のため
    @hospitals = Hospital.excluding_system_admin # システム管理病院を除外した病院一覧

    # パスワード変更なしがチェックされている場合は、パスワードパラメータを削除
    if params[:skip_password_update].present?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    @user = User.new(user_params)

    @selected_hospital_ids = params[:selected_hospitals]&.reject(&:blank?)&.map(&:to_i) || []
    @global_role_ids = params[:global_role_ids] || []
    @system_admin_selected = @global_role_ids.include?(@global_roles.find_by(name: 'システム管理者')&.id.to_s)
    @hospital_admins = params[:hospital_admin] || {}
    @hospital_patients = params[:hospital_patient] || {}
    @hospital_medical_roles = params[:hospital_medical_roles] || {}

    # バリデーション
    if @selected_hospital_ids.empty?
      @user.errors.add(:base, '少なくとも1つの病院を選択してください')
      render :new, status: :unprocessable_entity
      return
    end

    # 各選択された病院で患者、医療従事者、または病院管理者の役割が選択されているかチェック
    @selected_hospital_ids.each do |hospital_id|
      has_admin = @hospital_admins[hospital_id.to_s].present?
      has_patient = @hospital_patients[hospital_id.to_s].present?
      has_medical_roles = @hospital_medical_roles[hospital_id.to_s]&.reject(&:blank?)&.present?

      if !has_admin && !has_patient && !has_medical_roles
        hospital = Hospital.find(hospital_id)
        @user.errors.add(:base, "#{hospital.name}で患者、医療従事者、または病院管理者の役割を少なくとも1つ選択してください")
      end
    end

    unless @user.errors.empty?
      render :new, status: :unprocessable_entity
      return
    end

    # まずはユーザー情報を保存（current_role_idは後で設定）
    if @user.save
      # グローバル役割の割り当て（全体）
      @global_role_ids.each do |role_id|
        role = @global_roles.find_by(id: role_id.to_i)
        if role
          # システム管理の場合はシステム管理病院に割り当て
          if role.name == 'システム管理者'
            system_hospital = Hospital.find_by(name: 'システム管理')
            if system_hospital
              UserHospitalRole.create!(
                user: @user,
                hospital: system_hospital,
                role: role
              )
            end
          end
        end
      end

      # 病院毎の役割割り当て
      patient_role = Role.find_by(name: '患者')

      @selected_hospital_ids.each do |hospital_id|
        hospital = Hospital.find(hospital_id)
        is_hospital_admin = @hospital_admins[hospital_id.to_s].present?

        # 患者として選択された場合
        if @hospital_patients[hospital_id.to_s].present?
          UserHospitalRole.create!(
            user: @user,
            hospital: hospital,
            role: patient_role,
            permission_level: 0  # 患者は常にpermission_level = 0
          )
        end

        # 医療従事者の役割が選択された場合
        if @hospital_medical_roles[hospital_id.to_s].present?
          medical_role_ids = @hospital_medical_roles[hospital_id.to_s]&.reject(&:blank?)&.map(&:to_i) || []
          medical_role_ids.each do |role_id|
            role = Role.find(role_id)
            UserHospitalRole.create!(
              user: @user,
              hospital: hospital,
              role: role,
              permission_level: is_hospital_admin ? 1 : 0  # 病院管理者の場合はpermission_level = 1
            )
          end
        end
      end

      # current_role_idを適切に設定（バリデーションとコールバックをスキップ）
      assigned_role_ids = @user.user_hospital_roles.pluck(:role_id).uniq
      if assigned_role_ids.any?
        @user.update_column(:current_role_id, assigned_role_ids.first)
      end

      redirect_to admin_user_path(@user), notice: 'ユーザーを登録しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @user_roles = @user.user_hospital_roles.includes(:role, :hospital).distinct
    @hospitals = @user.hospitals.distinct
  end

  def edit
    @global_roles = Role.where(is_hospital_role: false) # 病院非依存の役割
    @hospital_roles = Role.where(is_hospital_role: true) # 病院毎の役割
    @medical_roles = Role.where(is_hospital_role: true, is_medical_staff: true) # 医療従事者の役割
    @roles = @medical_roles # ビューでの互換性のため
    @hospitals = Hospital.excluding_system_admin # システム管理病院を除外した病院一覧

    # 既存ユーザーの病院・役割情報を取得（システム管理病院は除外）
    @existing_hospital_roles = {}
    @user.user_hospital_roles.includes(:hospital, :role).where.not(hospitals: { id: 1 }).each do |uhr|
      hospital_id = uhr.hospital_id
      @existing_hospital_roles[hospital_id] ||= {
        hospital_name: uhr.hospital.name,
        roles: []
      }

      # 重複チェック：同じ role_id が既に存在しない場合のみ追加
      unless @existing_hospital_roles[hospital_id][:roles].any? { |r| r[:role_id] == uhr.role_id }
        @existing_hospital_roles[hospital_id][:roles] << {
          role_id: uhr.role_id,
          role_name: uhr.role.name,
          is_patient: uhr.role.name == '患者',
          is_medical_staff: uhr.role.is_medical_staff,
          permission_level: UserHospitalRole.permission_levels[uhr.permission_level]
        }
      end
    end

    # 既存ユーザーのグローバル役割を取得
    @existing_global_role_ids = @user.user_hospital_roles.joins(:role).where(roles: { is_hospital_role: false }).pluck(:role_id).uniq

  end

  def update
    @global_roles = Role.where(is_hospital_role: false) # 病院非依存の役割
    @hospital_roles = Role.where(is_hospital_role: true) # 病院毎の役割
    @medical_roles = Role.where(is_hospital_role: true, is_medical_staff: true) # 医療従事者の役割
    @roles = @medical_roles # ビューでの互換性のため
    @hospitals = Hospital.excluding_system_admin # システム管理病院を除外した病院一覧

    # パスワード変更なしがチェックされている場合は、パスワードパラメータを削除
    if params[:skip_password_update].present?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    new_hospital_ids = params[:selected_hospitals]&.reject(&:blank?)&.map(&:to_i) || []
    new_global_role_ids = params[:global_role_ids] || []
    new_system_admin_selected = new_global_role_ids.include?(@global_roles.find_by(name: 'システム管理者')&.id.to_s)
    new_hospital_admins = params[:hospital_admin] || {}
    new_hospital_patients = params[:hospital_patient] || {}
    new_hospital_medical_roles = params[:hospital_medical_roles] || {}


    # バリデーション
    if new_hospital_ids.empty?
      @user.errors.add(:base, '少なくとも1つの病院を選択してください')
      @staff_roles = @user.user_hospital_roles.includes(:role, :hospital)
      @current_global_role_ids = @user.user_hospital_roles.joins(:role).where(roles: { is_hospital_role: false }).pluck(:role_id).uniq
      @is_system_admin = @user.user_hospital_roles.joins(:hospital, :role).where(hospitals: { name: 'システム管理' }, roles: { name: 'システム管理者' }).exists?

      # 既存ユーザーの病院・役割情報を設定（バリデーションエラー時に表示するため）
      @existing_hospital_roles = {}
      @user.user_hospital_roles.joins(:role, :hospital).where.not(hospitals: { id: 1 }).each do |uhr|
        hospital_id = uhr.hospital_id
        @existing_hospital_roles[hospital_id] ||= {
          hospital_name: uhr.hospital.name,
          roles: []
        }

        # 重複チェック：同じ role_id が既に存在しない場合のみ追加
        unless @existing_hospital_roles[hospital_id][:roles].any? { |r| r[:role_id] == uhr.role_id }
          @existing_hospital_roles[hospital_id][:roles] << {
            role_id: uhr.role_id,
            role_name: uhr.role.name,
            is_patient: uhr.role.name == '患者',
            is_medical_staff: uhr.role.is_medical_staff,
            permission_level: UserHospitalRole.permission_levels[uhr.permission_level]
          }
        end
      end

      # 既存ユーザーのグローバル役割を取得
      @existing_global_role_ids = @user.user_hospital_roles.joins(:role).where(roles: { is_hospital_role: false }).pluck(:role_id).uniq

      render :edit, status: :unprocessable_entity
      return
    end

    # 各選択された病院で患者、医療従事者、または病院管理者の役割が選択されているかチェック
    new_hospital_ids.each do |hospital_id|
      has_admin = new_hospital_admins[hospital_id.to_s].present?
      has_patient = new_hospital_patients[hospital_id.to_s].present?
      has_medical_roles = new_hospital_medical_roles[hospital_id.to_s]&.reject(&:blank?)&.present?

      if !has_admin && !has_patient && !has_medical_roles
        hospital = Hospital.find(hospital_id)
        @user.errors.add(:base, "#{hospital.name}で患者、医療従事者、または病院管理者の役割を少なくとも1つ選択してください")
      end
    end

    unless @user.errors.empty?
      @staff_roles = @user.user_hospital_roles.includes(:role, :hospital)
      @current_global_role_ids = @user.user_hospital_roles.joins(:role).where(roles: { is_hospital_role: false }).pluck(:role_id).uniq
      @is_system_admin = @user.user_hospital_roles.joins(:hospital, :role).where(hospitals: { name: 'システム管理' }, roles: { name: 'システム管理者' }).exists?

      # 既存ユーザーの病院・役割情報を設定（バリデーションエラー時に表示するため）
      @existing_hospital_roles = {}
      @user.user_hospital_roles.joins(:role, :hospital).where.not(hospitals: { id: 1 }).each do |uhr|
        hospital_id = uhr.hospital_id
        @existing_hospital_roles[hospital_id] ||= {
          hospital_name: uhr.hospital.name,
          roles: []
        }

        # 重複チェック：同じ role_id が既に存在しない場合のみ追加
        unless @existing_hospital_roles[hospital_id][:roles].any? { |r| r[:role_id] == uhr.role_id }
          @existing_hospital_roles[hospital_id][:roles] << {
            role_id: uhr.role_id,
            role_name: uhr.role.name,
            is_patient: uhr.role.name == '患者',
            is_medical_staff: uhr.role.is_medical_staff,
            permission_level: UserHospitalRole.permission_levels[uhr.permission_level]
          }
        end
      end

      # 既存ユーザーのグローバル役割を取得
      @existing_global_role_ids = @user.user_hospital_roles.joins(:role).where(roles: { is_hospital_role: false }).pluck(:role_id).uniq

      render :edit, status: :unprocessable_entity
      return
    end

    # まずはユーザー情報を保存（current_role_idは後で設定）
    if @user.update(user_params)
      # 既存の病院関連をすべて削除（システム管理者関連以外）
      @user.user_hospital_roles.joins(:hospital).where.not(hospitals: { name: 'システム管理' }).destroy_all

      # グローバル役割の更新
      system_hospital = Hospital.find_by(name: 'システム管理')
      if system_hospital
        system_admin_role = @global_roles.find_by(name: 'システム管理者')
        if system_admin_role
          if new_system_admin_selected
            # システム管理者を選択した場合
            unless @user.user_hospital_roles.exists?(hospital: system_hospital, role: system_admin_role)
              UserHospitalRole.create!(
                user: @user,
                hospital: system_hospital,
                role: system_admin_role
              )
            end
          else
            # システム管理者を選択していない場合、システム管理者役割を削除
            @user.user_hospital_roles.where(hospital: system_hospital, role: system_admin_role).destroy_all
          end
        end
      end

      # 病院毎の役割割り当て
      patient_role = Role.find_by(name: '患者')

      new_hospital_ids.each do |hospital_id|
        hospital = Hospital.find(hospital_id)
        is_hospital_admin = new_hospital_admins[hospital_id.to_s].present?

        # 患者として選択された場合
        if new_hospital_patients[hospital_id.to_s].present?
          UserHospitalRole.create!(
            user: @user,
            hospital: hospital,
            role: patient_role,
            permission_level: 0  # 患者は常にpermission_level = 0
          )
        end

        # 医療従事者の役割が選択された場合
        if new_hospital_medical_roles[hospital_id.to_s].present?
          medical_role_ids = new_hospital_medical_roles[hospital_id.to_s]&.reject(&:blank?)&.map(&:to_i) || []
          medical_role_ids.each do |role_id|
            role = Role.find(role_id)
            UserHospitalRole.create!(
              user: @user,
              hospital: hospital,
              role: role,
              permission_level: is_hospital_admin ? 1 : 0  # 病院管理者の場合はpermission_level = 1
            )
          end
        end
      end

      # 所属外れた病院の担当患者関係を削除
      PatientStaffAssignment.where(staff: @user)
                           .where.not(hospital_id: new_hospital_ids)
                           .destroy_all

      # current_role_idを適切に設定（バリデーションとコールバックをスキップ）
      assigned_role_ids = @user.user_hospital_roles.pluck(:role_id).uniq
      if assigned_role_ids.any?
        @user.update_column(:current_role_id, assigned_role_ids.first)
      end

      redirect_to admin_user_path(@user), notice: 'ユーザー情報を更新しました。'
    else
      @staff_roles = @user.user_hospital_roles.includes(:role, :hospital)
      @current_global_role_ids = @user.user_hospital_roles.joins(:role).where(roles: { is_hospital_role: false }).pluck(:role_id).uniq
      @is_system_admin = @user.user_hospital_roles.joins(:hospital, :role).where(hospitals: { name: 'システム管理' }, roles: { name: 'システム管理者' }).exists?

      # 既存ユーザーの病院・役割情報を設定（バリデーションエラー時に表示するため）
      @existing_hospital_roles = {}
      @user.user_hospital_roles.joins(:role, :hospital).where.not(hospitals: { id: 1 }).each do |uhr|
        hospital_id = uhr.hospital_id
        @existing_hospital_roles[hospital_id] ||= {
          hospital_name: uhr.hospital.name,
          roles: []
        }

        # 重複チェック：同じ role_id が既に存在しない場合のみ追加
        unless @existing_hospital_roles[hospital_id][:roles].any? { |r| r[:role_id] == uhr.role_id }
          @existing_hospital_roles[hospital_id][:roles] << {
            role_id: uhr.role_id,
            role_name: uhr.role.name,
            is_patient: uhr.role.name == '患者',
            is_medical_staff: uhr.role.is_medical_staff,
            permission_level: UserHospitalRole.permission_levels[uhr.permission_level]
          }
        end
      end

      # 既存ユーザーのグローバル役割を取得
      @existing_global_role_ids = @user.user_hospital_roles.joins(:role).where(roles: { is_hospital_role: false }).pluck(:role_id).uniq

      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to admin_users_path, notice: "#{@user.name} を削除しました。"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
