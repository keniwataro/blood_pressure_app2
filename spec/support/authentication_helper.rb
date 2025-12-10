module AuthenticationHelper
  def sign_in(user)
    # Wardenを使って直接ログイン
    login_as(user, scope: :user)
  end

  def sign_in_via_form(user)
    visit new_user_session_path
    # ページが完全に読み込まれるまで待つ
    sleep 1 # ページ読み込みを待つ
    expect(page).to have_content('ログイン')
    # フィールドが利用可能になるまで待つ
    expect(page).to have_field('user[user_id]')
    expect(page).to have_field('user[password]')
    fill_in 'user[user_id]', with: user.user_id
    fill_in 'user[password]', with: user.password
    click_button 'ログイン'
  end

  def sign_in_as_patient
    patient = create(:user, :patient)
    sign_in(patient)
    patient
  end

  def sign_in_as_medical_staff
    staff = create(:user, :medical_staff)
    sign_in(staff)
    staff
  end

  def sign_in_as_administrator
    admin = create(:user, :administrator)
    sign_in(admin)
    admin
  end

  def sign_in_as_system_admin
    sys_admin = create(:user, :system_admin)
    sign_in(sys_admin)
    sys_admin
  end

  def current_user
    User.find_by(id: session[:user_id])
  end

  def user_signed_in?
    current_user.present?
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :system
  config.include AuthenticationHelper, type: :feature
end
