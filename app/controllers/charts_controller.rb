class ChartsController < ApplicationController
  def index
    @period = params[:period] || 'all'
    
    # 年月・週の指定を取得
    @year = params[:year]&.to_i || Time.current.year
    @month = params[:month]&.to_i || Time.current.month
    @week_offset = params[:week_offset]&.to_i || 0
    
    # 期間に応じてデータを取得
    case @period
    when 'week'
      # 週の開始日（月曜日）を計算
      today = Time.current.beginning_of_day
      current_week_start = today.beginning_of_week(:monday)
      @week_start = current_week_start + @week_offset.weeks
      @week_end = @week_start.end_of_week(:sunday).end_of_day
      
      # 現在週かどうかを判定
      @is_current_week = @week_offset == 0
      
      @blood_pressure_records = current_user.blood_pressure_records
                                 .where(measured_at: @week_start..@week_end)
      @date_range_start = @week_start
      @date_range_end = @week_end
      
    when 'month'
      # 指定された年月の1日から月末まで
      @month_start = Time.zone.local(@year, @month, 1).beginning_of_day
      @month_end = @month_start.end_of_month.end_of_day
      
      # 現在月かどうかを判定
      current_year_month = [Time.current.year, Time.current.month]
      @is_current_month = [@year, @month] == current_year_month
      
      @blood_pressure_records = current_user.blood_pressure_records
                                 .where(measured_at: @month_start..@month_end)
      @date_range_start = @month_start
      @date_range_end = @month_end
      
    else
      # 全期間
      @blood_pressure_records = current_user.blood_pressure_records.all
      @date_range_start = nil
      @date_range_end = nil
    end
    
    @blood_pressure_records = @blood_pressure_records.order(:measured_at)
    
    # グラフ用のデータを準備
    @chart_data = prepare_chart_data
    
    respond_to do |format|
      format.html
      format.json { render json: @chart_data }
    end
  end

  private

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
    # 月曜から日曜までの7日間のラベルを作成
    labels = []
    systolic_data = []
    diastolic_data = []
    pulse_data = []
    
    # 日付ごとにレコードをグループ化
    records_by_date = @blood_pressure_records.group_by { |r| r.measured_at.to_date }
    
    7.times do |i|
      current_date = @week_start + i.days
      day_of_week = %w[日 月 火 水 木 金 土][current_date.wday]
      
      # その日のデータを取得（複数ある場合は全て追加）
      day_records = records_by_date[current_date.to_date] || []
      
      if day_records.any?
        day_records.each do |record|
          time_str = record.measured_at.strftime('%H:%M')
          # 3行表示：日付、曜日、時刻
          labels << [current_date.strftime('%m/%d'), "(#{day_of_week})", time_str]
          systolic_data << record.systolic_pressure
          diastolic_data << record.diastolic_pressure
          pulse_data << record.pulse_rate
        end
      else
        # データがない日も表示（2行表示：日付、曜日）
        labels << [current_date.strftime('%m/%d'), "(#{day_of_week})"]
        systolic_data << nil
        diastolic_data << nil
        pulse_data << nil
      end
    end
    
    { labels: labels, systolic: systolic_data, diastolic: diastolic_data, pulse: pulse_data }
  end

  def prepare_month_chart_data
    # 1日から月末までの全日付のラベルを作成
    labels = []
    systolic_data = []
    diastolic_data = []
    pulse_data = []
    
    # 日付ごとにレコードをグループ化
    records_by_date = @blood_pressure_records.group_by { |r| r.measured_at.to_date }
    
    days_in_month = @month_end.day
    days_in_month.times do |i|
      current_date = @month_start + i.days
      
      # その日のデータを取得（複数ある場合は全て追加）
      day_records = records_by_date[current_date.to_date] || []
      
      if day_records.any?
        day_records.each do |record|
          # 午前/午後を判定
          time_period = record.measured_at.hour < 12 ? "午前" : "午後"
          # 2行表示：日付、午前/午後
          labels << [current_date.strftime('%m/%d'), time_period]
          systolic_data << record.systolic_pressure
          diastolic_data << record.diastolic_pressure
          pulse_data << record.pulse_rate
        end
      else
        # データがない日も表示（1行表示：日付のみ）
        labels << [current_date.strftime('%m/%d')]
        systolic_data << nil
        diastolic_data << nil
        pulse_data << nil
      end
    end
    
    { labels: labels, systolic: systolic_data, diastolic: diastolic_data, pulse: pulse_data }
  end

  def prepare_all_chart_data
    # 全期間の場合は実際のデータのみ表示
    {
      labels: @blood_pressure_records.map { |record| 
        date_str = record.measured_at.strftime("%m/%d")
        time_str = record.measured_at.hour < 12 ? "午前" : "午後"
        [date_str, time_str]
      },
      systolic: @blood_pressure_records.map(&:systolic_pressure),
      diastolic: @blood_pressure_records.map(&:diastolic_pressure),
      pulse: @blood_pressure_records.map(&:pulse_rate)
    }
  end
end
