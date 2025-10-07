require "active_support/core_ext/integer/time"

Rails.application.configure do
  # ここで指定された設定は、config/application.rb の設定よりも優先されます。

  # リクエスト間でコードがリロードされません。
  config.enable_reloading = false

  # 起動時にコードをeager loadします。これによりほとんどのRailsと
  # アプリケーションがメモリにロードされ、スレッド化されたウェブサーバーと
  # copy on writeに依存するサーバーの両方がより良いパフォーマンスを発揮できます。
  # Rakeタスクはパフォーマンスのためにこのオプションを自動的に無視します。
  config.eager_load = true

  # 完全なエラーレポートが無効になり、キャッシュがオンになります。
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # マスターキーがENV["RAILS_MASTER_KEY"]、config/master.key、または
  # config/credentials/production.keyなどの環境キーで利用可能であることを保証します。
  # このキーはcredentials（および他の暗号化されたファイル）を復号するために使用されます。
  # config.require_master_key = true

  # NGINX/Apacheに依存して代わりにpublic/から静的ファイルを提供することを無効にします。
  # config.public_file_server.enabled = false

  # プリプロセッサーを使用してCSSを圧縮します。
  # config.assets.css_compressor = :sass

  # プリコンパイルされたアセットが見つからない場合、アセットパイプラインにフォールバックしない。
  config.assets.compile = false

  # アセットサーバーから画像、スタイルシート、JavaScriptを提供できるようにします。
  # config.asset_host = "http://assets.example.com"

  # サーバーがファイル送信に使用するヘッダーを指定します。
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # アップロードされたファイルをローカルファイルシステムに保存します（オプションについてはconfig/storage.ymlを参照）。
  config.active_storage.service = :local

  # Action Cableをメインのプロセスまたはドメイン外にマウントします。
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # アプリへのすべてのアクセスがSSL終端リバースプロキシを経由していると仮定します。
  # config.force_sslと組み合わせてStrict-Transport-Securityとセキュアクッキーを使用できます。
  # config.assume_ssl = true

  # アプリへのすべてのアクセスをSSL経由で強制し、Strict-Transport-Securityを使用し、セキュアクッキーを使用します。
  config.force_ssl = true

  # デフォルトでSTDOUTにログを出力
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # すべてのログ行に以下のタグを先頭に付加します。
  config.log_tags = [ :request_id ]

  # "info"はシステム操作に関する一般的な有用な情報を含みますが、個人識別情報（PII）の
  # 偶発的な露出を避けるために過度な情報のログを避けます。
  # すべてをログに記録したい場合は、レベルを"debug"に設定してください。
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # 本番環境で異なるキャッシュストアを使用します。
  # config.cache_store = :mem_cache_store

  # Active Jobで実際のキューイングバックエンドを使用します（環境ごとにキューを分離）。
  # config.active_job.queue_adapter = :resque
  # config.active_job.queue_name_prefix = "app_production"

  config.action_mailer.perform_caching = false

  # 不正なメールアドレスを無視し、メール配信エラーを発生させません。
  # これをtrueに設定し、即時配信のためにメールサーバーを設定すると配信エラーが発生します。
  # config.action_mailer.raise_delivery_errors = false

  # I18nのロケールフォールバックを有効にします（翻訳が見つからない場合、
  # 任意のロケールの検索をI18n.default_localeにフォールバックさせます）。
  config.i18n.fallbacks = true

  # 非推奨のログを記録しません。
  config.active_support.report_deprecations = false

  # マイグレーション後にスキーマをダンプしません。
  config.active_record.dump_schema_after_migration = false

  # DNSリバインディング保護とその他の`Host`ヘッダー攻撃を有効にします。
  # config.hosts = [
  #   "example.com",     # example.comからのリクエストを許可
  #   /.*\.example\.com/ # www.example.comのようなサブドメインからのリクエストを許可
  # ]
  # デフォルトのヘルスチェックエンドポイントのDNSリバインディング保護をスキップします。
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
