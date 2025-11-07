module AuthorizationHelper
  include Warden::Test::Helpers

  def expect_to_be_authorized
    expect(page).to have_current_path(root_path)
    expect(page).not_to have_content("アクセス権限がありません")
  end

  def expect_to_be_unauthorized
    expect(page).to have_content("アクセス権限がありません").or have_content("ログインしてください")
  end

  def expect_to_require_patient_role
    expect(page).to have_content("アクセス権限がありません")
  end

  def expect_to_require_medical_staff_role
    expect(page).to have_content("アクセス権限がありません")
  end

  def expect_to_require_administrator_role
    expect(page).to have_content("アクセス権限がありません")
  end

  def expect_to_require_system_admin_role
    expect(page).to have_content("アクセス権限がありません")
  end

  # リクエストスペック用のヘルパー - Deviseのsign_inを使用
  def authenticate_user(user)
    sign_in user
  end

  def authenticate_request(user)
    sign_in user
  end

  # CSRFトークンを含むヘッダーを生成
  def csrf_headers
    token = session[:_csrf_token] ||= SecureRandom.base64(32)
    { 'X-CSRF-Token' => token }
  end

  def expect_forbidden_response
    expect(response).to have_http_status(:forbidden)
  end

  def expect_unauthorized_response
    expect(response).to have_http_status(:unauthorized)
  end

  def expect_success_response
    expect(response).to have_http_status(:success)
  end

  def expect_redirect_response
    expect(response).to have_http_status(:redirect)
  end

  def expect_created_response
    expect(response).to have_http_status(:created).or have_http_status(:redirect)
  end
end

RSpec.configure do |config|
  config.include AuthorizationHelper, type: :system
  config.include AuthorizationHelper, type: :feature
  config.include AuthorizationHelper, type: :request
end
