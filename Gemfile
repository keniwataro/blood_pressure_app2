source "https://rubygems.org"

ruby "3.3.9"

# エッジ版Railsを使用する場合: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.5", ">= 7.1.5.2"

# Railsのオリジナルアセットパイプライン [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Active Recordのデータベースとしてpostgresqlを使用
gem "pg", "~> 1.1"

# Pumaウェブサーバーを使用 [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# ESM import mapsを使用したJavaScript [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# HotwireのSPAライクなページアクセラレーター [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwireの控えめなJavaScriptフレームワーク [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# JSON APIを簡単に構築 [https://github.com/rails/jbuilder]
gem "jbuilder"

# 本番環境でAction Cableを実行するためのRedisアダプター
# gem "redis", ">= 4.0.1"

# Redisでより高レベルなデータ型を取得 [https://github.com/rails/kredis]
# gem "kredis"

# Active Model has_secure_passwordを使用 [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# 認証
gem "devise"
gem "devise-i18n"

# スタイリングのためのBootstrap
gem "bootstrap", "~> 5.3"
gem "sassc-rails"

# Windowsにはzoneinfoファイルが含まれないため、tzinfo-data gemをバンドル
gem "tzinfo-data", platforms: %i[ windows jruby ]

# キャッシュによる起動時間の短縮。config/boot.rbで必須
gem "bootsnap", require: false

# Active Storageバリアントを使用 [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# ページネーション
gem "kaminari"

# Slimテンプレートエンジンを使用
# gem "slim-rails"

group :development, :test do
  # https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem を参照
  gem "debug", platforms: %i[ mri windows ]

  # RSpec
  gem "rspec-rails", "~> 6.0.0"
  # 統合テストで使用
  gem "rails-controller-testing"
  # binding.pryで使用
  gem 'pry-rails'
  gem 'pry-byebug'

  # テストデータ生成
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  # 例外ページでコンソールを使用 [https://github.com/rails/web-console]
  gem "web-console"

  # 速度バッジを追加 [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # 遅いマシン/大規模アプリでコマンドを高速化 [https://github.com/rails/spring]
  # gem "spring"

  # コード品質とスタイルチェックのためのRuboCop
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-performance", require: false

  # 開発環境向けのより良いエラーページ
  gem "better_errors"
  gem "binding_of_caller"

  # セキュリティ脆弱性スキャナー
  gem "brakeman", require: false

  # パフォーマンス最適化 - N+1クエリ検出
  gem "bullet"

  # モデルとルートにスキーマ情報を注釈付け
  gem "annotate"

  # ウェブインターフェースでブラウザでメールをプレビュー
  gem "letter_opener_web", "~> 2.0"
end

group :test do
  # システムテストを使用 [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # テストカバレッジ測定とレポート
  gem "simplecov", require: false

  # データベースクリーンアップ
  gem "database_cleaner-active_record"
end