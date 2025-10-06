# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 開発環境でのサンプルデータ作成
if Rails.env.development?
  # テストユーザーの作成
  user = User.find_or_create_by(email: 'test@example.com') do |u|
    u.name = 'テストユーザー'
    u.password = 'password'
    u.password_confirmation = 'password'
  end

  puts "テストユーザー作成完了: #{user.email}"

  # 血圧記録のサンプルデータ作成（過去30日分）
  if user.blood_pressure_records.empty?
    30.times do |i|
      date = i.days.ago
      
      # ランダムな血圧データ（正常～軽度高血圧の範囲）
      systolic = rand(110..150)
      diastolic = rand(70..95)
      pulse = rand(60..90)
      
      user.blood_pressure_records.create!(
        systolic_pressure: systolic,
        diastolic_pressure: diastolic,
        pulse_rate: pulse,
        measured_at: date + rand(8..20).hours,
        memo: i % 5 == 0 ? "調子#{['良好', '普通', 'やや疲れ気味'][rand(3)]}" : nil
      )
    end
    puts "血圧記録30件作成完了"
  end

  # 病院のサンプルデータ
  if Hospital.count == 0
    hospitals = [
      {
        name: '○○総合病院',
        address: '東京都渋谷区○○1-2-3',
        phone_number: '03-1234-5678',
        website: 'https://example-hospital.com'
      },
      {
        name: '△△内科クリニック',
        address: '東京都新宿区△△4-5-6',
        phone_number: '03-9876-5432',
        website: nil
      }
    ]

    hospitals.each do |hospital_data|
      Hospital.create!(hospital_data)
    end
    puts "病院データ2件作成完了"
  end

  puts "サンプルデータの作成が完了しました。"
  puts "ログイン情報:"
  puts "  Email: test@example.com"
  puts "  Password: password"
end
