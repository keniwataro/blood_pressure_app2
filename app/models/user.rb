# == Schema Information
#
# Table name: users
#
#  id                       :bigint           not null, primary key
#  email                    :string           default(""), not null
#  encrypted_password       :string           default(""), not null
#  name                     :string
#  remember_created_at      :datetime
#  reset_password_sent_at   :datetime
#  reset_password_token     :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  current_hospital_role_id :bigint
#  user_id                  :string
#
# Indexes
#
#  index_users_on_current_hospital_role_id  (current_hospital_role_id)
#  index_users_on_email                     (email) UNIQUE
#  index_users_on_reset_password_token      (reset_password_token) UNIQUE
#  index_users_on_user_id                   (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_current_hospital_role_id  (current_hospital_role_id => user_hospital_roles.id)
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         authentication_keys: [:user_id]

  # アソシエーション
  has_many :blood_pressure_records, dependent: :destroy
  has_many :user_hospital_roles, dependent: :destroy
  has_many :hospitals, through: :user_hospital_roles
  has_many :roles, through: :user_hospital_roles
  belongs_to :current_hospital_role, class_name: 'UserHospitalRole', optional: true
  
  # 患者としての担当スタッフ関連
  has_many :patient_staff_assignments_as_patient, 
           class_name: 'PatientStaffAssignment', 
           foreign_key: 'patient_id', 
           dependent: :destroy
  has_many :assigned_staff, 
           through: :patient_staff_assignments_as_patient, 
           source: :staff
  
  # スタッフとしての担当患者関連
  has_many :patient_staff_assignments_as_staff, 
           class_name: 'PatientStaffAssignment', 
           foreign_key: 'staff_id', 
           dependent: :destroy
  has_many :assigned_patients, 
           through: :patient_staff_assignments_as_staff, 
           source: :patient

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
  validates :user_id, presence: true, uniqueness: true, format: { with: /\A\d+\z/, message: "は数字のみで入力してください" }
  validates :email, presence: true, uniqueness: true
  # validates :current_hospital_role_id, presence: true # current_role_must_be_assignedでチェック
  validate :current_role_must_be_assigned
  
  # コールバック
  before_validation :generate_user_id, on: :create
  attr_readonly :user_id
  
  # メールアドレスのバリデーションをカスタマイズ（Deviseのデフォルトを上書き）
  def email_required?
    false
  end
  
  def email_changed?
    false
  end
  
  # メソッド
  def medical_staff?
    user_hospital_roles.joins(:role).where(roles: { is_medical_staff: true }).exists?
  end
  
  def patient?
    user_hospital_roles.joins(:role).where(roles: { is_medical_staff: false }).exists?
  end
  
  def hospitals_as_staff
    hospitals.joins(:user_hospital_roles).merge(
      UserHospitalRole.joins(:role).merge(Role.medical_staff)
    ).where(user_hospital_roles: { user_id: id }).distinct
  end
  
  def hospitals_as_patient
    hospitals.joins(:user_hospital_roles).merge(
      UserHospitalRole.joins(:role).merge(Role.patients)
    ).where(user_hospital_roles: { user_id: id }).distinct
  end
  
  # 特定の病院での管理者権限チェック
  def administrator_at?(hospital)
    user_hospital_roles
      .joins(:role)
      .where(hospital_id: hospital.id, roles: { is_medical_staff: true })
      .where(permission_level: :administrator)
      .exists?
  end
  
  # いずれかの病院で管理者権限を持っているかチェック
  def administrator?
    user_hospital_roles
      .joins(:role)
      .where(roles: { is_medical_staff: true })
      .permission_level_administrator
      .exists?
  end
  
  # 特定の病院での担当スタッフを取得
  def assigned_staff_at(hospital)
    assigned_staff.joins(:user_hospital_roles)
      .where(user_hospital_roles: { hospital_id: hospital.id })
      .distinct
  end
  
  # 特定の病院での担当患者を取得
  def assigned_patients_at(hospital)
    assigned_patients.joins(:user_hospital_roles)
      .where(user_hospital_roles: { hospital_id: hospital.id })
      .distinct
  end
  
  # 利用可能な役割を取得
  def available_roles
    roles.distinct
  end
  
  # 複数の役割を持っているかチェック
  def has_multiple_roles?
    available_roles.count > 1
  end
  
  # 現在の役割が医療従事者かチェック
  def current_role_medical_staff?
    current_hospital_role&.role&.is_medical_staff == true
  end

  # 現在の役割が患者かチェック
  def current_role_patient?
    current_hospital_role&.role&.is_medical_staff == false
  end

  # 現在の役割を取得（後方互換性のため）
  def current_role
    current_hospital_role&.role
  end
  
  # 役割を切り替え
  def switch_to_role!(role_id)
    role = available_roles.find_by(id: role_id)
    if role
      # 指定されたrole_idを持つuser_hospital_rolesレコードのIDを設定
      user_hospital_role = user_hospital_roles.find_by(role_id: role_id)
      if user_hospital_role
        update_column(:current_hospital_role_id, user_hospital_role.id)
      end
    end
  end
  
  # システム管理者かチェック
  def system_admin?
    current_hospital_role&.role&.is_hospital_role == false
  end
  
  private
  
  def generate_user_id
    return if user_id.present?
    
    loop do
      # 7桁のランダムな数字を生成
      new_user_id = rand(1000000..9999999).to_s
      break self.user_id = new_user_id unless User.exists?(user_id: new_user_id)
    end
  end
  
  
  # current_role_idが自分の持つ役割の中にあるかチェック
  def current_role_must_be_assigned
    return if current_hospital_role_id.blank?

    # 新規作成時はスキップ（まだuser_hospital_rolesが作成されていないため）
    return if new_record?

    # current_hospital_role_idから該当のuser_hospital_roleレコードを取得
    current_user_hospital_role = user_hospital_roles.find_by(id: current_hospital_role_id)

    unless current_user_hospital_role
      errors.add(:current_hospital_role_id, "は自分に割り当てられた役割ではありません")
      return
    end

    # 自分が持っている役割のIDリストを取得
    assigned_role_ids = roles.pluck(:id)

    unless assigned_role_ids.include?(current_user_hospital_role.role_id)
      errors.add(:current_hospital_role_id, "は自分に割り当てられた役割ではありません")
    end
  end
end
