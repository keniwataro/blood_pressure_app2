class BloodPressureRecordsController < ApplicationController
  before_action :set_blood_pressure_record, only: [:show, :edit, :confirm_edit, :update, :destroy]

  def index
    @blood_pressure_records = current_user.blood_pressure_records.recent
    @recent_records = @blood_pressure_records.limit(10)
  end

  def show
  end

  def new
    @blood_pressure_record = current_user.blood_pressure_records.build
    # 秒を0にリセットして分単位にする
    now = Time.current
    @blood_pressure_record.measured_at = now.change(sec: 0)
  end

  def confirm_new
    @blood_pressure_record = current_user.blood_pressure_records.build(blood_pressure_record_params)
    
    if @blood_pressure_record.valid?
      render :confirm_new
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create
    @blood_pressure_record = current_user.blood_pressure_records.build(blood_pressure_record_params)
    
    if @blood_pressure_record.save
      redirect_to @blood_pressure_record, notice: '血圧記録を登録しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def confirm_edit
    @blood_pressure_record.assign_attributes(blood_pressure_record_params)
    
    if @blood_pressure_record.valid?
      render :confirm_edit
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update
    if @blood_pressure_record.update(blood_pressure_record_params)
      redirect_to @blood_pressure_record, notice: '血圧記録を更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @blood_pressure_record.destroy
    redirect_to blood_pressure_records_url, notice: t('flash.blood_pressure_records.destroyed')
  end

  private

  def set_blood_pressure_record
    @blood_pressure_record = current_user.blood_pressure_records.find(params[:id])
  end

  def blood_pressure_record_params
    permitted_params = params.require(:blood_pressure_record).permit(:systolic_pressure, :diastolic_pressure, :pulse_rate, :measured_at, :memo)
    
    # 測定日時の秒を0にリセット
    if permitted_params[:measured_at].present?
      begin
        # 既にdatetime-local形式（YYYY-MM-DDTHH:MM）の場合と、秒付きの場合の両方に対応
        if permitted_params[:measured_at].is_a?(String)
          # 秒が含まれていない場合は:00を追加
          datetime_str = permitted_params[:measured_at]
          datetime_str += ":00" unless datetime_str.match?(/:\d{2}$/)
          # Time.zone.parseを使用してタイムゾーンを考慮
          measured_time = Time.zone.parse(datetime_str)
        else
          measured_time = permitted_params[:measured_at]
        end
        
        # 秒とミリ秒を0に設定
        permitted_params[:measured_at] = measured_time.change(sec: 0, usec: 0)
      rescue ArgumentError => e
        Rails.logger.warn "Invalid datetime format: #{permitted_params[:measured_at]}, error: #{e.message}"
        # エラーの場合は現在時刻を使用（秒は0）
        permitted_params[:measured_at] = Time.current.change(sec: 0, usec: 0)
      end
    end
    
    permitted_params
  end
end
