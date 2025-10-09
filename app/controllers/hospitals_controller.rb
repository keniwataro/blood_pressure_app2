class HospitalsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_medical_staff!
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

    # システム管理病院の作成を防ぐ
    if @hospital.name == 'システム管理'
      redirect_to new_hospital_url, alert: 'システム管理病院は作成できません。'
      return
    end

    if @hospital.save
      redirect_to @hospital, notice: '病院を登録しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def confirm_edit
    @hospital.assign_attributes(hospital_params)

    # システム管理病院の編集を防ぐ
    if @hospital.id == 1
      redirect_to hospitals_url, alert: 'システム管理病院は編集できません。'
      return
    end

    if @hospital.valid?
      render :confirm_edit
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update
    if @hospital.update(hospital_params)
      redirect_to @hospital, notice: '病院情報を更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # システム管理病院の削除を防ぐ
    if @hospital.id == 1
      redirect_to hospitals_url, alert: 'システム管理病院は削除できません。'
      return
    end

    @hospital.destroy
    redirect_to hospitals_url, notice: t('flash.hospitals.destroyed')
  end

  private

  def set_hospital
    @hospital = Hospital.find(params[:id])

    # システム管理病院の編集・削除を防ぐ
    if @hospital.id == 1
      redirect_to hospitals_url, alert: 'システム管理病院は編集・削除できません。'
      return
    end
  end

  def hospital_params
    params.require(:hospital).permit(:name, :address, :phone_number, :website)
  end

  def authorize_medical_staff!
    unless current_user.medical_staff?
      redirect_to root_path, alert: '医療従事者のみアクセスできます。'
    end
  end
end
