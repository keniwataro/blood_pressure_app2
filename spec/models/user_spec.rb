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
require 'rails_helper'

RSpec.describe User, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
