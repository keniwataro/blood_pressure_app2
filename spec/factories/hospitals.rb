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
FactoryBot.define do
  factory :hospital do
    name { "MyString" }
    address { "MyText" }
    phone_number { "MyString" }
    website { "MyString" }
  end
end
