class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_system_admin!

  layout 'admin'
  
  private
  
  def authorize_system_admin!
    unless current_user.system_admin?
      flash[:alert] = 'システム管理者としてログインしてください。'
      redirect_to root_path
    end
  end
  
  def system_hospital
    @system_hospital ||= Hospital.find(1)
  end
  helper_method :system_hospital
end
