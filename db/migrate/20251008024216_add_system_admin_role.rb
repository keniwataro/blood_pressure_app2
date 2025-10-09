class AddSystemAdminRole < ActiveRecord::Migration[7.1]
  def up
    # 既存のrolesテーブルのIDシーケンスをリセット
    # システム管理者用の役割をid=1で作成するため
    
    # 既存のid=1のレコードがあれば削除
    execute "DELETE FROM roles WHERE id = 1"
    
    # シーケンスを1にリセット
    execute "ALTER SEQUENCE roles_id_seq RESTART WITH 1"
    
    # システム管理者の役割を作成
    Role.create!(
      id: 1,
      name: 'システム管理者',
      is_medical_staff: false,
      description: 'システム全体を管理する管理者'
    )
    
    # シーケンスを次の値に設定
    execute "SELECT setval('roles_id_seq', (SELECT MAX(id) FROM roles))"
    
    # 既存のhospitalsテーブルのIDシーケンスをリセット
    # システム管理用の病院をid=1で作成するため
    
    # 既存のid=1のレコードがあれば削除（関連データも削除）
    execute "DELETE FROM patient_staff_assignments WHERE hospital_id = 1"
    execute "DELETE FROM user_hospital_roles WHERE hospital_id = 1"
    execute "DELETE FROM hospitals WHERE id = 1"
    
    # シーケンスを1にリセット
    execute "ALTER SEQUENCE hospitals_id_seq RESTART WITH 1"
    
    # システム管理用の病院を作成（バリデーションをスキップ）
    hospital = Hospital.new(
      id: 1,
      name: 'システム管理',
      address: 'システム管理用',
      phone_number: nil,
      website: nil
    )
    hospital.save!(validate: false)
    
    # シーケンスを次の値に設定
    execute "SELECT setval('hospitals_id_seq', (SELECT MAX(id) FROM hospitals))"
  end
  
  def down
    # ロールバック時の処理
    Role.where(id: 1).destroy_all
    Hospital.where(id: 1).destroy_all
  end
end
