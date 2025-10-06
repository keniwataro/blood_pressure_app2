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
  # バリデーション
  validates :name, presence: true, length: { maximum: 100 }
  validates :address, presence: true, length: { maximum: 255 }
  validates :phone_number, format: { with: /\A[\d\-\(\)\s]+\z/, message: "は有効な電話番号を入力してください" }, allow_blank: true
  validates :website, format: { with: URI::regexp(%w[http https]), message: "は有効なURLを入力してください" }, allow_blank: true

  # スコープ
  scope :with_name, ->(name) { where("name ILIKE ?", "%#{name}%") }
end
