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

    # パスワード変更なしがチェックされている場合は、パスワードパラメータを削除
    user_params_copy = user_params.dup
    if params[:skip_password_update].present?
      user_params_copy.delete(:password)
      user_params_copy.delete(:password_confirmation)
      user_params_copy.delete(:current_password)
    end

    # current_hospital_role_idを保持してから属性を更新
    original_current_hospital_role_id = @user.current_hospital_role_id
    @user.assign_attributes(user_params_copy.except(:current_password, :password, :password_confirmation))
    @user.current_hospital_role_id = original_current_hospital_role_id

    @has_password_change = user_params[:password].present? && user_params[:password_confirmation].present? && params[:skip_password_update].blank?
    Rails.logger.debug "has_password_change判定結果: #{@has_password_change}"

    # パスワードパラメータをビューで使用するために保存
    @password = user_params[:password] if @has_password_change
    @password_confirmation = user_params[:password_confirmation] if @has_password_change
    @current_password = user_params[:current_password] if @has_password_change

    # パスワード変更がある場合は現在のパスワードと新しいパスワードのバリデーションを行う
    if @has_password_change
      unless @user.valid_password?(user_params[:current_password])
        @user.errors.add(:current_password, "が正しくありません")
        render :edit, status: :unprocessable_entity
        return
      end

      # 新しいパスワードのバリデーションを行う
      temp_user = User.new(password: user_params[:password], password_confirmation: user_params[:password_confirmation])
      unless temp_user.valid?
        temp_user.errors.each do |attribute, message|
          if attribute.to_s.start_with?('password')
            @user.errors.add(attribute, message)
          end
        end
        if @user.errors.any?
          render :edit, status: :unprocessable_entity
          return
        end
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

    # パスワード変更なしがチェックされている場合は、パスワードパラメータを削除
    if params[:skip_password_update].present?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    # パスワード変更がある場合はcurrent_passwordを保持、ない場合は除外
    if user_params[:password].blank?
      params[:user].delete(:current_password)
    end

    # パスワード変更がある場合
    if user_params[:password].present?
      # パスワード更新（Deviseのupdate_with_passwordを使用）
      password_params = user_params.slice(:current_password, :password, :password_confirmation)
      if @user.update_with_password(password_params)
        # パスワード更新成功後、名前とメールアドレスも更新
        profile_params = user_params.except(:current_password, :password, :password_confirmation)
        if profile_params.present?
          @user.update(profile_params)
        end
        bypass_sign_in(@user) # 再ログイン不要にする
        redirect_to profile_path, notice: 'プロフィールとパスワードを更新しました。'
      else
        render :edit, status: :unprocessable_entity
      end
    else
      # パスワード変更なしの場合
      # ユーザー情報を更新
      if @user.update(user_params)
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
