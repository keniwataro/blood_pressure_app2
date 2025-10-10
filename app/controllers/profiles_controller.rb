class ProfilesController < ApplicationController
  before_action :authenticate_user!
  
  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def confirm
    @user = current_user
    # current_hospital_role_idを保持してから属性を更新
    original_current_hospital_role_id = @user.current_hospital_role_id
    @user.assign_attributes(user_params.except(:current_password, :password, :password_confirmation))
    @user.current_hospital_role_id = original_current_hospital_role_id
    
    @has_password_change = user_params[:password].present?
    
    # パスワード変更がある場合は現在のパスワードをチェック
    if @has_password_change
      unless @user.valid_password?(user_params[:current_password])
        @user.errors.add(:current_password, "が正しくありません")
        render :edit, status: :unprocessable_entity
        return
      end
    end
    
    if @user.valid?
      render :confirm
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update
    @user = current_user
    
    # パスワード変更がある場合
    if user_params[:password].present?
      # 現在のパスワードが正しいかチェック
      unless @user.valid_password?(user_params[:current_password])
        @user.errors.add(:current_password, "が正しくありません")
        render :edit, status: :unprocessable_entity
        return
      end
      
      # パスワード更新（Deviseのupdate_with_passwordを使用）
      if @user.update_with_password(user_params)
        bypass_sign_in(@user) # 再ログイン不要にする
        redirect_to profile_path, notice: 'プロフィールとパスワードを更新しました。'
      else
        render :edit, status: :unprocessable_entity
      end
    else
      # パスワード変更なしの場合
      # current_passwordを除外してupdate
      update_params = user_params.except(:current_password, :password, :password_confirmation)
      
      if @user.update(update_params)
        redirect_to profile_path, notice: 'プロフィールを更新しました。'
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  private

  def user_params
    # user_idは変更不可なので除外
    params.require(:user).permit(:name, :email, :current_password, :password, :password_confirmation)
  end
end
