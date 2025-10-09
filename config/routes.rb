Rails.application.routes.draw do
  # Deviseのルート設定（registrationsを無効化）
  devise_for :users, skip: [:registrations]
  
  # システム管理者用の画面
  namespace :admin do
    root 'dashboard#index'
    resources :users, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  end
  
  # 医療従事者用の画面
  namespace :medical_staff do
    root 'dashboard#index'
  end
  
  # ルートページ（患者か医療従事者かで振り分け）
  authenticated :user do
    root to: 'dashboard#index', as: :authenticated_root
  end
  root 'blood_pressure_records#index'
  
  # 役割切り替え
  post 'switch_role', to: 'dashboard#switch_role'
  
  # 血圧記録のRESTfulルート
  resources :blood_pressure_records do
    collection do
      post 'confirm_new'
    end
    member do
      post 'confirm_edit'
    end
  end
  
  # 病院のRESTfulルート
  resources :hospitals do
    collection do
      post 'confirm_new'
    end
    member do
      post 'confirm_edit'
    end
  end
  
  # プロフィール管理
  resource :profile, only: [:show, :edit, :update] do
    post 'confirm', on: :collection
  end
  
  # グラフ表示
  get 'charts', to: 'charts#index'
  
  # ホームページ
  get 'home/index'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
