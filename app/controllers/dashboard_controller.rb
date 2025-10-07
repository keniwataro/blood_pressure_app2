class DashboardController < ApplicationController
  def index
    if current_user.medical_staff?
      redirect_to medical_staff_root_path
    else
      redirect_to blood_pressure_records_path
    end
  end
end