# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 役割マスターデータの作成（全環境で実行）
puts "役割マスターデータの作成..."

# マイグレーションで作成されたシステム管理者を確認
system_admin_role = Role.find_by(id: 1, name: 'システム管理者')
if system_admin_role.nil?
  # マイグレーションで作成されていない場合は作成
  Role.create!(
    id: 1,
    name: 'システム管理者',
    is_medical_staff: false,
    is_hospital_role: false,
    description: 'システム全体を管理する管理者'
  )
  puts "システム管理者役割を作成しました"
end

# 役割データ
roles_data = [
  { name: '患者', is_medical_staff: false, is_hospital_role: true, description: '血圧記録を行う患者' },
  { name: '医師', is_medical_staff: true, is_hospital_role: true, description: '診療を行う医師' },
  { name: '看護師', is_medical_staff: true, is_hospital_role: true, description: '看護業務を行う看護師' },
  { name: '薬剤師', is_medical_staff: true, is_hospital_role: true, description: '調剤業務を行う薬剤師' },
  { name: '医療事務', is_medical_staff: true, is_hospital_role: true, description: '受付・事務業務を行う医療事務' },
  { name: '臨床検査技師', is_medical_staff: true, is_hospital_role: true, description: '検査業務を行う臨床検査技師' },
  { name: '放射線技師', is_medical_staff: true, is_hospital_role: true, description: '放射線業務を行う放射線技師' },
  { name: '理学療法士', is_medical_staff: true, is_hospital_role: true, description: 'リハビリ業務を行う理学療法士' }
]

# 役割を作成（既存データは上書きしない）
roles_data.each do |role_data|
  role = Role.find_by(name: role_data[:name])
  if role.nil?
    begin
      Role.create!(
        name: role_data[:name],
        is_medical_staff: role_data[:is_medical_staff],
        is_hospital_role: role_data[:is_hospital_role],
        description: role_data[:description]
      )
    rescue ActiveRecord::RecordNotUnique
      # 万一idが重複する場合は次のidで作成
      Role.create!(
        name: role_data[:name],
        is_medical_staff: role_data[:is_medical_staff],
        is_hospital_role: role_data[:is_hospital_role],
        description: role_data[:description]
      )
    end
  end
end

puts "役割マスターデータ作成完了: #{Role.count}件"

# 開発環境でのサンプルデータ作成
if Rails.env.development?
  puts "既存データをクリア中..."

  # データをクリア（システム管理関連データ以外）
  BloodPressureRecord.destroy_all
  PatientStaffAssignment.destroy_all
  UserHospitalRole.destroy_all
  User.destroy_all
  Hospital.where.not(id: 1).destroy_all

  puts "既存データのクリア完了"

  # 病院のサンプルデータ（既存データは上書きしない）
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
    },
    {
      name: '□□外科医院',
      address: '東京都港区□□7-8-9',
      phone_number: '03-5555-6666',
      website: 'https://surgical-clinic.example.com'
    },
    {
      name: '★★大学病院',
      address: '東京都文京区★★10-11-12',
      phone_number: '03-7777-8888',
      website: 'https://university-hospital.example.com'
    },
    {
      name: '★★★小児科クリニック',
      address: '東京都世田谷区★★★13-14-15',
      phone_number: '03-9999-0000',
      website: nil
    }
  ]

  hospitals_data.each do |hospital_data|
    Hospital.find_or_create_by(name: hospital_data[:name]) do |hospital|
      hospital.address = hospital_data[:address]
      hospital.phone_number = hospital_data[:phone_number]
      hospital.website = hospital_data[:website]
    end
  end
  puts "病院データ#{hospitals_data.size}件作成完了"

  # 役割の取得
  patient_role = Role.find_by(name: '患者')
  doctor_role = Role.find_by(name: '医師')
  nurse_role = Role.find_by(name: '看護師')
  clerk_role = Role.find_by(name: '医療事務')
  pharmacist_role = Role.find_by(name: '薬剤師')

  # システム管理病院を除外して通常の病院を取得
  normal_hospitals = Hospital.where.not(id: 1)
  hospital1 = normal_hospitals.first
  hospital2 = normal_hospitals.second

  # 1. テストユーザー（患者のみ）
  patient_user = User.create!(
    name: 'テスト患者',
    email: 'patient@example.com',
    password: 'password',
    password_confirmation: 'password'
  )
  patient_user_hospital_role = UserHospitalRole.create!(
    user: patient_user,
    hospital: hospital1,
    role: patient_role
  )
  # current_hospital_role_idを設定
  patient_user.update(current_hospital_role_id: patient_user_hospital_role.id)
  puts "患者ユーザー作成: #{patient_user.name} (ユーザーID: #{patient_user.user_id}) - 役割: 患者"

  # 2. 医師（管理者）
  doctor_user = User.create!(
    name: '山田太郎',
    email: 'doctor@example.com',
    password: 'password',
    password_confirmation: 'password'
  )
  doctor_user_hospital_role = UserHospitalRole.create!(
    user: doctor_user,
    hospital: hospital1,
    role: doctor_role,
    permission_level: :administrator
  )
  # current_hospital_role_idを設定
  doctor_user.update(current_hospital_role_id: doctor_user_hospital_role.id)
  puts "医師ユーザー作成: #{doctor_user.name} (ユーザーID: #{doctor_user.user_id}) - 役割: 医師 (管理者)"

  # 3. 看護師（一般）
  nurse_user = User.create!(
    name: '佐藤花子',
    email: 'nurse@example.com',
    password: 'password',
    password_confirmation: 'password'
  )
  nurse_user_hospital_role = UserHospitalRole.create!(
    user: nurse_user,
    hospital: hospital1,
    role: nurse_role,
    permission_level: :general
  )
  # current_hospital_role_idを設定
  nurse_user.update(current_hospital_role_id: nurse_user_hospital_role.id)
  puts "看護師ユーザー作成: #{nurse_user.name} (ユーザーID: #{nurse_user.user_id}) - 役割: 看護師 (一般)"

  # 4. 医療事務（一般）
  clerk_user = User.create!(
    name: '鈴木一郎',
    email: 'clerk@example.com',
    password: 'password',
    password_confirmation: 'password'
  )
  clerk_user_hospital_role = UserHospitalRole.create!(
    user: clerk_user,
    hospital: hospital1,
    role: clerk_role,
    permission_level: :general
  )
  # current_hospital_role_idを設定
  clerk_user.update(current_hospital_role_id: clerk_user_hospital_role.id)
  puts "医療事務ユーザー作成: #{clerk_user.name} (ユーザーID: #{clerk_user.user_id}) - 役割: 医療事務 (一般)"

  # 5. 複数の役割を持つユーザー（医師 + 看護師）
  multi_role_user1 = User.create!(
    name: '田中次郎',
    email: 'multi1@example.com',
    password: 'password',
    password_confirmation: 'password'
  )
  doctor_role_uhr = UserHospitalRole.create!(
    user: multi_role_user1,
    hospital: hospital1,
    role: doctor_role,
    permission_level: :administrator
  )
  UserHospitalRole.create!(
    user: multi_role_user1,
    hospital: hospital1,
    role: nurse_role,
    permission_level: :general
  )
  # current_hospital_role_idを設定（最初の役割）
  multi_role_user1.update(current_hospital_role_id: doctor_role_uhr.id)
  puts "複数役割ユーザー作成: #{multi_role_user1.name} (ユーザーID: #{multi_role_user1.user_id}) - 役割: 医師 + 看護師 (現在: 医師)"

  # 6. 複数の役割を持つユーザー（患者 + 医療事務）
  multi_role_user2 = User.create!(
    name: '高橋美咲',
    email: 'multi2@example.com',
    password: 'password',
    password_confirmation: 'password'
  )
  patient_role_uhr = UserHospitalRole.create!(
    user: multi_role_user2,
    hospital: hospital1,
    role: patient_role
  )
  UserHospitalRole.create!(
    user: multi_role_user2,
    hospital: hospital1,
    role: clerk_role,
    permission_level: :general
  )
  # current_hospital_role_idを設定（最初の役割）
  multi_role_user2.update(current_hospital_role_id: patient_role_uhr.id)
  puts "複数役割ユーザー作成: #{multi_role_user2.name} (ユーザーID: #{multi_role_user2.user_id}) - 役割: 患者 + 医療事務 (現在: 患者)"

  # 7. 複数の役割を持つユーザー（医師 + 薬剤師 + 患者）
  multi_role_user3 = User.create!(
    name: '伊藤健一',
    email: 'multi3@example.com',
    password: 'password',
    password_confirmation: 'password'
  )
  doctor_role_uhr3 = UserHospitalRole.create!(
    user: multi_role_user3,
    hospital: hospital1,
    role: doctor_role,
    permission_level: :administrator
  )
  UserHospitalRole.create!(
    user: multi_role_user3,
    hospital: hospital1,
    role: pharmacist_role,
    permission_level: :general
  )
  UserHospitalRole.create!(
    user: multi_role_user3,
    hospital: hospital2,
    role: patient_role
  )
  # current_hospital_role_idを設定（最初の役割）
  multi_role_user3.update(current_hospital_role_id: doctor_role_uhr3.id)
  puts "複数役割ユーザー作成: #{multi_role_user3.name} (ユーザーID: #{multi_role_user3.user_id}) - 役割: 医師 + 薬剤師 + 患者 (現在: 医師)"

  # 血圧記録のサンプルデータ作成（患者ユーザー用）
  30.times do |i|
    date = i.days.ago
    
    # ランダムな血圧データ（正常～軽度高血圧の範囲）
    systolic = rand(110..150)
    diastolic = rand(70..95)
    pulse = rand(60..90)
    
    patient_user.blood_pressure_records.create!(
      systolic_pressure: systolic,
      diastolic_pressure: diastolic,
      pulse_rate: pulse,
      measured_at: Time.zone.parse("#{date.strftime('%Y-%m-%d')} #{rand(8..20)}:#{rand(0..59)}:00"),
      memo: i % 5 == 0 ? "調子#{['良好', '普通', 'やや疲れ気味'][rand(3)]}" : nil
    )
  end
  puts "血圧記録30件作成完了 (#{patient_user.name})"

  # 複数役割を持つ患者の血圧記録
  15.times do |i|
    date = i.days.ago
    systolic = rand(110..140)
    diastolic = rand(70..90)
    pulse = rand(65..85)
    
    multi_role_user2.blood_pressure_records.create!(
      systolic_pressure: systolic,
      diastolic_pressure: diastolic,
      pulse_rate: pulse,
      measured_at: Time.zone.parse("#{date.strftime('%Y-%m-%d')} #{rand(9..19)}:#{rand(0..59)}:00")
    )
  end
  puts "血圧記録15件作成完了 (#{multi_role_user2.name})"

  # 医師兼患者の血圧記録
  10.times do |i|
    date = i.days.ago
    systolic = rand(115..145)
    diastolic = rand(75..92)
    pulse = rand(62..88)
    
    multi_role_user3.blood_pressure_records.create!(
      systolic_pressure: systolic,
      diastolic_pressure: diastolic,
      pulse_rate: pulse,
      measured_at: Time.zone.parse("#{date.strftime('%Y-%m-%d')} #{rand(10..18)}:#{rand(0..59)}:00")
    )
  end
  puts "血圧記録10件作成完了 (#{multi_role_user3.name})"

  # システム管理者アカウントの作成（マイグレーションで作成されたデータを前提）
  puts "\nシステム管理者アカウントを作成中..."

  # マイグレーションで作成されたデータを確認
  system_admin_role = Role.find_by(id: 1)
  system_hospital = Hospital.find_by(id: 1)

  if system_admin_role.nil?
    # マイグレーションで作成されていない場合のみ作成
    system_admin_role = Role.create!(
      id: 1,
      name: 'システム管理者',
      is_medical_staff: false,
      description: 'システム全体を管理する管理者'
    )
    puts "システム管理者役割を作成しました"
  end

  # システム管理病院を作成（既存のものは削除して再作成）
  system_hospital = Hospital.find_by(id: 1)
  if system_hospital.nil?
    system_hospital = Hospital.create!(
      id: 1,
      name: 'システム管理',
      address: 'システム管理用',
      phone_number: nil,
      website: nil
    )
    puts "システム管理病院を作成しました"
  else
    # 既に存在する場合は名前を更新
    system_hospital.update!(
      name: 'システム管理',
      address: 'システム管理用'
    )
    puts "システム管理病院を更新しました"
  end

  # システム管理者アカウント作成
  admin_user = User.find_or_initialize_by(email: 'admin@system.com')
  if admin_user.new_record?
    admin_user.assign_attributes(
      name: 'システム管理者',
      password: 'admin123',
      password_confirmation: 'admin123'
    )
    admin_user.save!

    # システム管理者をシステム管理病院に所属させる
    admin_user_hospital_role = UserHospitalRole.find_or_create_by!(
      user: admin_user,
      hospital: system_hospital,
      role: system_admin_role
    )
    # current_hospital_role_idを設定
    admin_user.update(current_hospital_role_id: admin_user_hospital_role.id)

    puts "システム管理者アカウント作成完了: #{admin_user.email} (パスワード: admin123)"
  else
    puts "システム管理者アカウントは既に存在します: #{admin_user.email}"
    # 既存のユーザーのcurrent_hospital_role_idを設定
    if admin_user.current_hospital_role_id.nil?
      admin_user_hospital_role = admin_user.user_hospital_roles.first
      if admin_user_hospital_role
        admin_user.update(current_hospital_role_id: admin_user_hospital_role.id)
        puts "既存システム管理者のcurrent_hospital_role_idを設定しました"
      end
    end

    # 既存のシステム管理者もシステム管理病院に所属させる
    unless admin_user.user_hospital_roles.exists?(hospital: system_hospital, role: system_admin_role)
      UserHospitalRole.find_or_create_by!(
        user: admin_user,
        hospital: system_hospital,
        role: system_admin_role
      )
      puts "既存のシステム管理者をシステム管理病院に所属させました"
    end
  end

  puts "\n========================================="
  puts "サンプルデータの作成が完了しました。"
  puts "=========================================\n"
  puts "【全アカウント】（パスワード: password）\n"

  User.all.each do |u|
    roles_info = u.user_hospital_roles.map do |uhr|
      permission = uhr.permission_level_administrator? ? ' (管理者)' : uhr.permission_level_general? ? ' (一般)' : ''
      "#{uhr.role_name}#{permission}"
    end.join(', ')
    current_role_name = u.current_role&.name || '未設定'
    puts "  ユーザーID: #{u.user_id} | 名前: #{u.name}"
    puts "    役割: #{roles_info}"
    puts "    現在の役割: #{current_role_name}"
    puts ""
  end

  puts "【病院】"
  Hospital.all.order(:id).each do |h|
    puts "  #{h.name} (ID: #{h.id}) - #{h.address}"
  end
  puts "  総病院数: #{Hospital.count}件"
  puts "=========================================\n"
end
