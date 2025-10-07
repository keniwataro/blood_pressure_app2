require "active_support/core_ext/integer/time"

Rails.application.configure do
  # ここで指定された設定は、config/application.rb の設定よりも優先されます。

  # 開発環境では、コードが変更されるたびにアプリケーションのコードがリロードされます。
  # これによりレスポンスタイムが遅くなりますが、コードを変更するたびにウェブサーバーを
  # 再起動する必要がないため、開発には最適です。
  config.enable_reloading = true

  # 起動時にコードをeager loadしない。
  config.eager_load = false

  # 完全なエラーレポートを表示します。
  config.consider_all_requests_local = true

  # サーバータイミングを有効化
  config.server_timing = true

  # キャッシュを有効/無効にします。デフォルトではキャッシュは無効です。
  # rails dev:cache を実行してキャッシュを切り替えられます。
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # アップロードされたファイルをローカルファイルシステムに保存します（オプションについてはconfig/storage.ymlを参照）。
  config.active_storage.service = :local

  # メーラーが送信できない場合でも気にしない。
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # 非推奨の通知をRailsロガーに表示します。
  config.active_support.deprecation = :log

  # 許可されていない非推奨に対して例外を発生させます。
  config.active_support.disallowed_deprecation = :raise

  # Active Supportに許可しない非推奨メッセージを伝えます。
  config.active_support.disallowed_deprecation_warnings = []

  # 保留中のマイグレーションがある場合、ページロード時にエラーを発生させます。
  config.active_record.migration_error = :page_load

  # ログ内のデータベースクエリをトリガーしたコードをハイライトします。
  config.active_record.verbose_query_logs = true

  # ログ内のバックグラウンドジョブをキューイングしたコードをハイライトします。
  config.active_job.verbose_enqueue_logs = true

  # アセットリクエストのロガー出力を抑制します。
  config.assets.quiet = true

  # 翻訳が見つからない場合にエラーを発生させます。
  # config.i18n.raise_on_missing_translations = true

  # レンダリングされたビューにファイル名を注釈付けします。
  # config.action_view.annotate_rendered_view_with_filenames = true

  # 任意のオリジンからのAction Cableアクセスを許可したい場合はコメントを解除してください。
  # config.action_cable.disable_request_forgery_protection = true

  # before_actionのonly/exceptオプションが欠落したアクションを参照する場合にエラーを発生させる
  config.action_controller.raise_on_missing_callback_actions = true


  if defined?(BetterErrors)
    # 開発環境で全IPアドレスを許可（Docker環境）
    BetterErrors::Middleware.allow_ip! "0.0.0.0/0"

    # より良いファイルパスの表示のためにアプリケーションロートを設定
    BetterErrors.application_root = Rails.root.to_s
  end

  # N+1クエリ検出のためのBullet設定
  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = false  # ブラウザのアラートを無効化
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.add_footer = false  # 画面下部の吹き出しを無効化
    Bullet.skip_html_injection = true  # HTML注入を無効化
  end

  # Letter Opener設定
  config.action_mailer.delivery_method = :letter_opener_web
  config.action_mailer.perform_deliveries = true

end
