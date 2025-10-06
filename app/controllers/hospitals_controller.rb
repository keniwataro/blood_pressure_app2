class HospitalsController < ApplicationController
  before_action :set_hospital, only: [:show, :edit, :update, :destroy]

  def index
    @hospitals = Hospital.all
    @hospitals = @hospitals.with_name(params[:search]) if params[:search].present?
  end

  def show
  end

  def new
    @hospital = Hospital.new
  end

  def create
    @hospital = Hospital.new(hospital_params)
    
    if @hospital.save
      redirect_to @hospital, notice: t('flash.hospitals.created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @hospital.update(hospital_params)
      redirect_to @hospital, notice: t('flash.hospitals.updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @hospital.destroy
    redirect_to hospitals_url, notice: t('flash.hospitals.destroyed')
  end

  private

  def set_hospital
    @hospital = Hospital.find(params[:id])
  end

  def hospital_params
    params.require(:hospital).permit(:name, :address, :phone_number, :website)
  end
end
