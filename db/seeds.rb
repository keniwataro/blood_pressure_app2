# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 役割マスターデータの作成（全環境で実行）
puts "役割マスターデータの作成..."

roles_data = [
  { name: '患者', is_medical_staff: false, description: '血圧記録を行う患者' },
  { name: '医師', is_medical_staff: true, description: '診療を行う医師' },
  { name: '看護師', is_medical_staff: true, description: '看護業務を行う看護師' },
  { name: '薬剤師', is_medical_staff: true, description: '調剤業務を行う薬剤師' },
  { name: '医療事務', is_medical_staff: true, description: '受付・事務業務を行う医療事務' },
  { name: '臨床検査技師', is_medical_staff: true, description: '検査業務を行う臨床検査技師' },
  { name: '放射線技師', is_medical_staff: true, description: '放射線業務を行う放射線技師' },
  { name: '理学療法士', is_medical_staff: true, description: 'リハビリ業務を行う理学療法士' }
]

roles_data.each do |role_data|
  Role.find_or_create_by(name: role_data[:name]) do |role|
    role.is_medical_staff = role_data[:is_medical_staff]
    role.description = role_data[:description]
  end
end

puts "役割マスターデータ作成完了: #{Role.count}件"

# 開発環境でのサンプルデータ作成
if Rails.env.development?
  # 病院のサンプルデータ（先に作成）
  if Hospital.count == 0
    hospitals_data = [
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

    hospitals_data.each do |hospital_data|
      Hospital.create!(hospital_data)
    end
    puts "病院データ2件作成完了"
  end

  # 役割の取得
  patient_role = Role.find_by(name: '患者')
  doctor_role = Role.find_by(name: '医師')
  nurse_role = Role.find_by(name: '看護師')
  clerk_role = Role.find_by(name: '医療事務')

  # テストユーザー（患者）の作成
  user = User.find_or_create_by(email: 'test@example.com') do |u|
    u.name = 'テストユーザー'
    u.password = 'password'
    u.password_confirmation = 'password'
  end

  # 患者として病院に登録
  hospital1 = Hospital.first
  if hospital1 && patient_role
    UserHospitalRole.find_or_create_by(
      user: user,
      hospital: hospital1,
      role: patient_role
    )
    puts "テストユーザーを患者として登録: #{user.name} (#{user.user_id})"
  end

  # 医療従事者のサンプルユーザー作成
  medical_staff_data = [
    { name: '山田太郎', email: 'doctor@example.com', role: doctor_role, permission_level: :administrator },
    { name: '佐藤花子', email: 'nurse@example.com', role: nurse_role, permission_level: :general },
    { name: '鈴木一郎', email: 'clerk@example.com', role: clerk_role, permission_level: :general }
  ]

  medical_staff_data.each do |staff_data|
    staff_user = User.find_or_create_by(email: staff_data[:email]) do |u|
      u.name = staff_data[:name]
      u.password = 'password'
      u.password_confirmation = 'password'
    end

    # 病院に医療従事者として登録
    if hospital1 && staff_data[:role]
      uhr = UserHospitalRole.find_or_initialize_by(
        user: staff_user,
        hospital: hospital1,
        role: staff_data[:role]
      )
      uhr.permission_level = staff_data[:permission_level]
      uhr.save!
      
      permission_label = uhr.permission_level_administrator? ? '管理者' : '一般'
      puts "医療従事者作成完了: #{staff_user.name} (#{staff_data[:role].name} - #{permission_label}) - ユーザーID: #{staff_user.user_id}"
    end
  end

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

  puts "\n========================================="
  puts "サンプルデータの作成が完了しました。"
  puts "=========================================\n"
  puts "【患者アカウント】"
  puts "  ユーザーID: #{user.user_id}"
  puts "  名前: #{user.name}"
  puts "  パスワード: password"
  puts ""
  puts "【医療従事者アカウント】"
  User.joins(:user_hospital_roles).merge(UserHospitalRole.joins(:role).merge(Role.medical_staff)).distinct.each do |staff|
    staff.user_hospital_roles.joins(:role).where(roles: { is_medical_staff: true }).each do |uhr|
      permission_label = uhr.permission_level_administrator? ? '管理者' : '一般'
      puts "  ユーザーID: #{staff.user_id} | 名前: #{staff.name} | 役割: #{uhr.role_name} (#{permission_label})"
    end
  end
  puts ""
  puts "【病院】"
  Hospital.all.each do |h|
    puts "  #{h.name}"
  end
  puts "=========================================\n"
end
