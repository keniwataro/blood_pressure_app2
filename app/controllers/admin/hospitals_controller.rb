class Admin::HospitalsController < Admin::BaseController
  before_action :set_hospital, only: [:show, :edit, :confirm_edit, :update, :destroy]

  def index
    @hospitals = Hospital.excluding_system_admin
    @hospitals = @hospitals.with_name(params[:search]) if params[:search].present?
  end

  def show
  end

  def new
    @hospital = Hospital.new
  end

  def confirm_new
    @hospital = Hospital.new(hospital_params)

    if @hospital.valid?
      render :confirm_new
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create
    @hospital = Hospital.new(hospital_params)

    if @hospital.save
      redirect_to admin_hospitals_path, notice: '病院を登録しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def confirm_edit
    @hospital.assign_attributes(hospital_params)

    if @hospital.valid?
      render :confirm_edit
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update
    if @hospital.update(hospital_params)
      redirect_to admin_hospitals_path, notice: '病院情報を更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @hospital.destroy
      redirect_to admin_hospitals_path, notice: "#{@hospital.name}を削除しました。"
    else
      redirect_to admin_hospitals_path, alert: '病院の削除に失敗しました。'
    end
  end

  private

  def set_hospital
    @hospital = Hospital.find(params[:id])
  end

  def hospital_params
    params.require(:hospital).permit(:name, :address, :phone_number, :website)
  end
end
