module FactoryBotHelper
  # 既存のFactoryをクリーンアップして再作成
  def recreate_factory(factory_name, **attributes)
    factory = create(factory_name, **attributes)
    factory.tap do |record|
      # 関連するレコードもクリーンアップ
      case factory_name.to_sym
      when :user
        record.user_hospital_roles.destroy_all
        record.blood_pressure_records.destroy_all
      when :hospital
        record.user_hospital_roles.destroy_all
      when :role
        record.user_hospital_roles.destroy_all
      end
    end
    factory
  end

  # 指定した数のレコードを作成
  def create_list_with_traits(factory_name, count, *traits, **attributes)
    traits = [:default] if traits.empty?
    create_list(factory_name, count, *traits, **attributes)
  end

  # テスト用の病院・ユーザー・役割の組み合わせを作成
  def create_test_environment(options = {})
    hospital = create(:hospital, options[:hospital_attributes] || {})
    patient_role = create(:role, :patient)
    doctor_role = create(:role, :doctor)

    patient = create(:user, :patient, options[:patient_attributes] || {}).tap do |user|
      user.user_hospital_roles.destroy_all
      create(:user_hospital_role, user: user, hospital: hospital, role: patient_role)
      user.update_column(:current_hospital_role_id, user.user_hospital_roles.first.id)
    end

    doctor = create(:user, :medical_staff, options[:doctor_attributes] || {}).tap do |user|
      user.user_hospital_roles.destroy_all
      create(:user_hospital_role, user: user, hospital: hospital, role: doctor_role)
      user.update_column(:current_hospital_role_id, user.user_hospital_roles.first.id)
    end

    {
      hospital: hospital,
      patient: patient,
      doctor: doctor,
      patient_role: patient_role,
      doctor_role: doctor_role
    }
  end

  # 血圧記録を複数作成
  def create_blood_pressure_records_for(user, count = 5, options = {})
    records = []
    base_time = options[:base_time] || Time.current

    count.times do |i|
      records << create(:blood_pressure_record,
        user: user,
        measured_at: base_time - i.days,
        **options.except(:base_time)
      )
    end

    records
  end
end

RSpec.configure do |config|
  config.include FactoryBotHelper
end
