# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  user_id                :string
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_user_id               (user_id) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         authentication_keys: [:user_id]

  # アソシエーション
  has_many :blood_pressure_records, dependent: :destroy

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
  validates :user_id, presence: true, uniqueness: true, format: { with: /\A\d+\z/, message: "は数字のみで入力してください" }
  validates :email, presence: true, uniqueness: true
  
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
  
  private
  
  def generate_user_id
    return if user_id.present?
    
    loop do
      # 7桁のランダムな数字を生成
      new_user_id = rand(1000000..9999999).to_s
      break self.user_id = new_user_id unless User.exists?(user_id: new_user_id)
    end
  end
end
