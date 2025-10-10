class BloodPressureRecordsController < ApplicationController
  before_action :set_blood_pressure_record, only: [:show, :edit, :confirm_edit, :update, :destroy]

  def index
    @blood_pressure_records = current_user.blood_pressure_records.recent

    # ページネーション設定
    @per_page = 10
    @current_page = (params[:page] || 1).to_i
    @current_page = 1 if @current_page < 1

    # 総件数を取得
    @total_count = @blood_pressure_records.count

    # ページネーション用のオフセットとリミットを計算
    offset = (@current_page - 1) * @per_page
    @blood_pressure_records_paginated = @blood_pressure_records.offset(offset).limit(@per_page)

    # 総ページ数を計算
    @total_pages = (@total_count.to_f / @per_page).ceil

    respond_to do |format|
      format.html
      format.csv { send_csv_data }
    end
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

  def import
    if params[:file].blank?
      redirect_to blood_pressure_records_path, alert: 'CSVファイルを選択してください。'
      return
    end

    begin
      result = import_csv(params[:file])
      redirect_to blood_pressure_records_path, notice: "#{result[:created]}件の新規登録、#{result[:updated]}件の更新が完了しました。"
    rescue => e
      redirect_to blood_pressure_records_path, alert: "インポートに失敗しました: #{e.message}"
    end
  end

  private

  def set_blood_pressure_record
    @blood_pressure_record = current_user.blood_pressure_records.find(params[:id])
  end

  def send_csv_data
    csv_data = generate_csv
    send_data csv_data,
      filename: "血圧記録_#{Time.current.strftime('%Y%m%d')}.csv",
      type: 'text/csv; charset=utf-8'
  end

  def generate_csv
    require 'csv'

    # UTF-8 BOMを付与してExcelでの文字化けを防ぐ
    bom = "\uFEFF"
    bom + CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << ['測定日時', '最高血圧(mmHg)', '最低血圧(mmHg)', '脈拍(bpm)', '血圧分類', 'メモ']

      @blood_pressure_records.each do |record|
        csv << [
          record.measured_at.strftime('%Y/%m/%d %H:%M'),
          record.systolic_pressure,
          record.diastolic_pressure,
          record.pulse_rate,
          record.blood_pressure_category,
          record.memo
        ]
      end
    end
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

  def import_csv(file)
    require 'csv'

    created_count = 0
    updated_count = 0
    errors = []

    # トランザクション内で処理（1つでもエラーがあればロールバック）
    ActiveRecord::Base.transaction do
      csv_text = file.read.force_encoding('UTF-8')
      csv_text = csv_text.sub("\uFEFF", '') # BOM削除
      Rails.logger.debug "CSV text length: #{csv_text.length}, first 200 chars: #{csv_text[0..200].inspect}"

      begin
        CSV.parse(csv_text, headers: true) do |row|
        Rails.logger.debug "Processing row: #{row.inspect}"

        # 必須フィールドのチェック
        systolic = row['最高血圧(mmHg)']&.strip
        diastolic = row['最低血圧(mmHg)']&.strip
        pulse = row['脈拍(bpm)']&.strip
        measured_at_str = row['測定日時']&.strip

        Rails.logger.debug "Fields - systolic: '#{systolic}', diastolic: '#{diastolic}', pulse: '#{pulse}', measured_at: '#{measured_at_str}'"

        # 全ての必須フィールドが空でないかチェック
        if measured_at_str.blank? || systolic.blank? || diastolic.blank? || pulse.blank?
          error_msg = "必須項目が空です (測定日時: '#{measured_at_str}', 最高血圧: '#{systolic}', 最低血圧: '#{diastolic}', 脈拍: '#{pulse}')"
          Rails.logger.error "Validation error: #{error_msg}"
          raise StandardError, error_msg
        end

        # 測定日時のフォーマットチェック（YYYY/M/D H:M形式）
        unless measured_at_str =~ /\A\d{4}\/\d{1,2}\/\d{1,2} \d{1,2}:\d{2}\z/
          error_msg = "#{measured_at_str}: 測定日時の形式が正しくありません。'YYYY/M/D H:M'形式で入力してください。"
          Rails.logger.error "Validation error: #{error_msg}"
          raise StandardError, error_msg
        end

        if systolic.blank? || diastolic.blank? || pulse.blank?
          error_msg = "#{measured_at_str}: 最高血圧、最低血圧、脈拍は必須項目です (最高血圧: '#{systolic}', 最低血圧: '#{diastolic}', 脈拍: '#{pulse}')"
          Rails.logger.error "Validation error: #{error_msg}"
          raise StandardError, error_msg
        end

        # 数値チェック
        unless systolic =~ /\A\d+\z/
          error_msg = "#{measured_at_str}: 最高血圧は数字で入力してください (最高血圧: '#{systolic}')"
          Rails.logger.error "Validation error: #{error_msg}"
          raise StandardError, error_msg
        end

        unless diastolic =~ /\A\d+\z/
          error_msg = "#{measured_at_str}: 最低血圧は数字で入力してください (最低血圧: '#{diastolic}')"
          Rails.logger.error "Validation error: #{error_msg}"
          raise StandardError, error_msg
        end

        unless pulse =~ /\A\d+\z/
          error_msg = "#{measured_at_str}: 脈拍は数字で入力してください (脈拍: '#{pulse}')"
          Rails.logger.error "Validation error: #{error_msg}"
          raise StandardError, error_msg
        end

        # 測定日時をパース
        measured_at = Time.zone.parse(measured_at_str)

        # 同じ測定日時のレコードを検索
        record = current_user.blood_pressure_records.find_or_initialize_by(measured_at: measured_at)

        # 属性を設定（空文字列はnilに変換）
        record.assign_attributes(
          systolic_pressure: systolic.present? ? systolic : nil,
          diastolic_pressure: diastolic.present? ? diastolic : nil,
          pulse_rate: pulse.present? ? pulse : nil,
          memo: row['メモ']&.strip.presence
        )

        # バリデーション
        unless record.valid?
          error_msg = "#{measured_at.strftime('%Y/%m/%d %H:%M')}: #{record.errors.full_messages.join(', ')}"
          Rails.logger.error "Model validation error: #{error_msg}"
          raise StandardError, error_msg
        end

        if record.new_record?
          record.save!
          created_count += 1
        else
          record.save!
          updated_count += 1
        end
      end
      rescue CSV::MalformedCSVError => e
        raise StandardError, "CSVファイルの形式が正しくありません: #{e.message}"
      rescue ArgumentError => e
        raise StandardError, "日時形式が正しくありません: #{e.message}"
      end

      raise StandardError, errors.join("\n") if errors.any?
    end

    { created: created_count, updated: updated_count }
  end
end
