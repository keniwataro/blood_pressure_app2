# == Schema Information
#
# Table name: roles
#
#  id               :bigint           not null, primary key
#  description      :string
#  is_medical_staff :boolean          default(FALSE), not null
#  name             :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_roles_on_name  (name) UNIQUE
#
require 'rails_helper'

RSpec.describe Role, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
