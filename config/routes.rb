Rails.application.routes.draw do
  devise_for :users
  
  # ルートページを血圧記録一覧に設定
  root 'blood_pressure_records#index'
  
  # 血圧記録のRESTfulルート
  resources :blood_pressure_records
  
  # 病院のRESTfulルート
  resources :hospitals
  
  # プロフィール管理
  resource :profile, only: [:show, :edit, :update]
  
  # グラフ表示
  get 'charts', to: 'charts#index'
  
  # ホームページ
  get 'home/index'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
