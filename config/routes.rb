Rails.application.routes.draw do
  # Deviseのルート設定（registrationsを無効化）
  devise_for :users, skip: [:registrations]
  
  # 医療従事者用の画面
  namespace :medical_staff do
    root 'dashboard#index'
    resources :patients, only: [:index, :show, :new, :create, :edit, :update] do
      resources :blood_pressure_records, only: [:index, :show]
      # 担当スタッフの設定
      post 'assign_staff', to: 'patients#assign_staff'
      delete 'unassign_staff/:staff_id', to: 'patients#unassign_staff', as: 'unassign_staff'
    end
    resources :staff, only: [:index, :show, :new, :create, :edit, :update]
  end
  
  # ルートページ（患者か医療従事者かで振り分け）
  authenticated :user do
    root to: 'dashboard#index', as: :authenticated_root
  end
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
