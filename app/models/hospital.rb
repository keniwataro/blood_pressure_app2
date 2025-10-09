# == Schema Information
#
# Table name: hospitals
#
#  id           :bigint           not null, primary key
#  address      :text
#  name         :string
#  phone_number :string
#  website      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Hospital < ApplicationRecord
  # アソシエーション
  has_many :user_hospital_roles, dependent: :destroy
  has_many :users, through: :user_hospital_roles
  has_many :roles, through: :user_hospital_roles
  
  # バリデーション
  validates :name, presence: true, length: { maximum: 100 }
  validates :address, presence: true, length: { maximum: 255 }
  validates :phone_number, format: { with: /\A[\d\-\(\)\s]+\z/, message: "は有効な電話番号を入力してください" }, allow_blank: true
  validates :website, format: { with: URI::regexp(%w[http https]), message: "は有効なURLを入力してください" }, allow_blank: true

  # スコープ
  scope :with_name, ->(name) { where("name ILIKE ?", "%#{name}%") }
  scope :excluding_system_admin, -> { where.not(id: 1) }
  scope :including_system_admin, -> { where(id: 1) }
  
  # メソッド
  def medical_staff
    users.joins(:user_hospital_roles).merge(UserHospitalRole.joins(:role).merge(Role.medical_staff)).distinct
  end
  
  def patients
    users.joins(:user_hospital_roles).merge(UserHospitalRole.joins(:role).merge(Role.patients)).distinct
  end
end
