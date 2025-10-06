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
require 'rails_helper'

RSpec.describe Hospital, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
