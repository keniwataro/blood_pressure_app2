class MedicalStaff::PatientsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_medical_staff!
  before_action :set_hospital
  before_action :set_patient, only: [:show, :edit, :confirm_edit, :update, :destroy, :assign_staff, :unassign_staff]

  def index
    @patients = @hospital.patients.includes(:blood_pressure_records)
    
    # 名前で検索
    if params[:search].present?
      @patients = @patients.where("users.name ILIKE ?", "%#{params[:search]}%")
    end
    
    # 担当フィルター
    if params[:assignment].present?
      case params[:assignment]
      when 'assigned'
        # 自分の担当患者のみ
        @patients = @patients.joins(:patient_staff_assignments_as_patient)
                            .where(patient_staff_assignments: { staff_id: current_user.id, hospital_id: @hospital.id })
                            .distinct
      when 'unassigned'
        # 自分の担当でない患者
        assigned_patient_ids = PatientStaffAssignment.where(staff_id: current_user.id, hospital_id: @hospital.id).pluck(:patient_id)
        @patients = @patients.where.not(id: assigned_patient_ids)
      end
    end
    
    @patients = @patients.order(created_at: :desc)
    @staff_members = @hospital.medical_staff.order(:name)
  end

  def show
    @blood_pressure_records = @patient.blood_pressure_records.recent.limit(20)
    @assigned_staff = @patient.assigned_staff_at(@hospital)
    
    # グラフ表示用のパラメータ
    @period = params[:period] || 'all'
    @year = params[:year]&.to_i || Time.current.year
    @month = params[:month]&.to_i || Time.current.month
    @week_offset = params[:week_offset]&.to_i || 0

    case @period
    when 'week'
      today = Time.current.beginning_of_day
      current_week_start = today.beginning_of_week(:monday)
      @week_start = current_week_start + @week_offset.weeks
      @week_end = @week_start.end_of_week(:sunday).end_of_day
      @is_current_week = @week_offset == 0
      @chart_records = @patient.blood_pressure_records
                               .where(measured_at: @week_start..@week_end)
    when 'month'
      @month_start = Time.zone.local(@year, @month, 1).beginning_of_day
      @month_end = @month_start.end_of_month.end_of_day
      current_year_month = [Time.current.year, Time.current.month]
      @is_current_month = [@year, @month] == current_year_month
      @chart_records = @patient.blood_pressure_records
                               .where(measured_at: @month_start..@month_end)
    else
      @chart_records = @patient.blood_pressure_records.all
    end

    @chart_records = @chart_records.order(:measured_at)
    @chart_data = prepare_chart_data
  end

  def new
    @patient = User.new
    @patient_role = Role.find_by(name: '患者')
    @staff_members = @hospital.medical_staff.order(:name)
  end

  def confirm_new
    @patient = User.new(patient_params)
    @patient_role = Role.find_by(name: '患者')
    @staff_members = @hospital.medical_staff.order(:name)
    @selected_staff_ids = params[:staff_ids]&.reject(&:blank?) || []
    
    if @patient.valid?
      render :confirm_new
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create
    @patient = User.new(patient_params)
    @patient_role = Role.find_by(name: '患者')

    # 患者として病院に登録
    UserHospitalRole.create!(
      user: @patient,
      hospital: @hospital,
      role: @patient_role
    )

    # current_hospital_role_idを設定
    @patient.current_hospital_role_id = @patient.user_hospital_roles.first.id

    if @patient.save
      
      # 担当スタッフの設定
      if params[:staff_ids].present?
        params[:staff_ids].reject(&:blank?).each do |staff_id|
          PatientStaffAssignment.create(
            patient: @patient,
            staff_id: staff_id,
            hospital: @hospital
          )
        end
      end
      
      redirect_to medical_staff_patient_path(@patient), notice: '患者を登録しました。'
    else
      @staff_members = @hospital.medical_staff.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @staff_members = @hospital.medical_staff.order(:name)
    @assigned_staff_ids = @patient.assigned_staff_at(@hospital).pluck(:id)
  end

  def confirm_edit
    # current_hospital_role_idを保持してから属性を更新
    original_current_hospital_role_id = @patient.current_hospital_role_id

    # patient_update_paramsを一時的に保存
    update_params = patient_update_params

    # assign_attributesを実行
    @patient.assign_attributes(update_params)

    # current_hospital_role_idを元に戻す（患者編集では役割は変更しない）
    @patient.current_hospital_role_id = original_current_hospital_role_id
    
    @staff_members = @hospital.medical_staff.order(:name)
    @selected_staff_ids = params[:staff_ids]&.reject(&:blank?)&.map(&:to_i) || []
    
    # バリデーションを実行するが、current_hospital_role_idのエラーは無視
    @patient.valid?
    @patient.errors.delete(:current_hospital_role_id)
    
    if @patient.errors.empty?
      render :confirm_edit
    else
      @assigned_staff_ids = @patient.assigned_staff_at(@hospital).pluck(:id)
      render :edit, status: :unprocessable_entity
    end
  end

  def update
    # current_hospital_role_idを保持してから更新
    original_current_hospital_role_id = @patient.current_hospital_role_id

    # current_role_must_be_assignedバリデーションを一時的にスキップ
    User.skip_callback(:validate, :current_role_must_be_assigned)

    begin
      if @patient.update(patient_update_params.except(:current_hospital_role_id))
        # current_hospital_role_idを直接更新
        @patient.current_hospital_role_id = original_current_hospital_role_id
        @patient.save(validate: false)

        # 担当スタッフの更新
        current_assignments = PatientStaffAssignment.where(patient: @patient, hospital: @hospital)
        new_staff_ids = params[:staff_ids].present? ? params[:staff_ids].reject(&:blank?).map(&:to_i) : []
        current_staff_ids = current_assignments.pluck(:staff_id)

        # 削除する担当
        staff_ids_to_remove = current_staff_ids - new_staff_ids
        current_assignments.where(staff_id: staff_ids_to_remove).destroy_all

        # 追加する担当
        staff_ids_to_add = new_staff_ids - current_staff_ids
        staff_ids_to_add.each do |staff_id|
          PatientStaffAssignment.create(
            patient: @patient,
            staff_id: staff_id,
            hospital: @hospital
          )
        end

        redirect_to medical_staff_patient_path(@patient), notice: '患者情報を更新しました。'
      else
        @staff_members = @hospital.medical_staff.order(:name)
        @assigned_staff_ids = @patient.assigned_staff_at(@hospital).pluck(:id)
        render :edit, status: :unprocessable_entity
      end
    ensure
      # コールバックを元に戻す
      User.set_callback(:validate, :current_role_must_be_assigned)
    end
  end

  def destroy
    # current_hospital_role_idが削除されるuser_hospital_rolesを参照している場合、nilに設定
    @patient.update_column(:current_hospital_role_id, nil)
    @patient.destroy
    redirect_to medical_staff_patients_path, notice: "#{@patient.name} を削除しました。"
  end

  # 担当スタッフを追加
  def assign_staff
    staff = @hospital.medical_staff.find(params[:staff_id])
    
    assignment = PatientStaffAssignment.new(
      patient: @patient,
      staff: staff,
      hospital: @hospital
    )
    
    if assignment.save
      redirect_to medical_staff_patients_path, notice: "#{staff.name}を#{@patient.name}の担当に設定しました。"
    else
      redirect_to medical_staff_patients_path, alert: "担当の設定に失敗しました: #{assignment.errors.full_messages.join(', ')}"
    end
  end
  
  # 担当スタッフを解除
  def unassign_staff
    staff = User.find(params[:staff_id])
    
    assignment = PatientStaffAssignment.find_by(
      patient: @patient,
      staff: staff,
      hospital: @hospital
    )
    
    if assignment&.destroy
      redirect_to medical_staff_patients_path, notice: "#{staff.name}を#{@patient.name}の担当から解除しました。"
    else
      redirect_to medical_staff_patients_path, alert: '担当の解除に失敗しました。'
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

  def set_patient
    patient_id = params[:id] || params[:patient_id]
    @patient = @hospital.patients.find(patient_id)
  rescue ActiveRecord::RecordNotFound
    redirect_to medical_staff_patients_path, alert: '患者が見つかりませんでした。'
  end

  def patient_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def patient_update_params
    params.require(:user).permit(:name, :email)
  end

  def prepare_chart_data
    case @period
    when 'week'
      prepare_week_chart_data
    when 'month'
      prepare_month_chart_data
    else
      prepare_all_chart_data
    end
  end

  def prepare_week_chart_data
    labels = []
    systolic_data = []
    diastolic_data = []
    pulse_data = []

    records_by_date = @chart_records.group_by { |r| r.measured_at.to_date }

    7.times do |i|
      current_date = @week_start + i.days
      day_of_week = %w[日 月 火 水 木 金 土][current_date.wday]

      day_records = records_by_date[current_date.to_date] || []

      if day_records.any?
        day_records.each do |record|
          time_str = record.measured_at.strftime('%H:%M')
          labels << [current_date.strftime('%m/%d'), "(#{day_of_week})", time_str]
          systolic_data << record.systolic_pressure
          diastolic_data << record.diastolic_pressure
          pulse_data << record.pulse_rate
        end
      else
        labels << [current_date.strftime('%m/%d'), "(#{day_of_week})"]
        systolic_data << nil
        diastolic_data << nil
        pulse_data << nil
      end
    end
    { labels: labels, systolic: systolic_data, diastolic: diastolic_data, pulse: pulse_data }
  end

  def prepare_month_chart_data
    labels = []
    systolic_data = []
    diastolic_data = []
    pulse_data = []

    records_by_date = @chart_records.group_by { |r| r.measured_at.to_date }

    days_in_month = @month_end.day
    days_in_month.times do |i|
      current_date = @month_start + i.days

      day_records = records_by_date[current_date.to_date] || []

      if day_records.any?
        day_records.each do |record|
          time_period = record.measured_at.hour < 12 ? "午前" : "午後"
          labels << [current_date.strftime('%m/%d'), time_period]
          systolic_data << record.systolic_pressure
          diastolic_data << record.diastolic_pressure
          pulse_data << record.pulse_rate
        end
      else
        labels << [current_date.strftime('%m/%d')]
        systolic_data << nil
        diastolic_data << nil
        pulse_data << nil
      end
    end
    { labels: labels, systolic: systolic_data, diastolic: diastolic_data, pulse: pulse_data }
  end

  def prepare_all_chart_data
    {
      labels: @chart_records.map { |record|
        date_str = record.measured_at.strftime("%m/%d")
        time_str = record.measured_at.hour < 12 ? "午前" : "午後"
        [date_str, time_str]
      },
      systolic: @chart_records.map(&:systolic_pressure),
      diastolic: @chart_records.map(&:diastolic_pressure),
      pulse: @chart_records.map(&:pulse_rate)
    }
  end
end