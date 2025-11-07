require "active_support/core_ext/integer/time"

# テスト環境は、アプリケーションのテストスイートを実行するためだけに使用されます。
# それ以外では使用する必要はありません。テストデータベースはテストスイートの
# 「スクラッチスペース」であり、テスト実行間で消去されて再作成されることに注意してください。
# そこにあるデータに依存しないでください！

Rails.application.configure do
  # ここで指定された設定は、config/application.rb の設定よりも優先されます。

  # テスト実行中はファイルが監視されないため、リロードは必要ありません。
  config.enable_reloading = false

  # Eager loadingはアプリケーション全体をロードします。ローカルで単一のテストを実行する場合、
  # これは通常必要ではなく、テストスイートを遅くする可能性があります。ただし、
  # 継続的インテグレーションシステムではeager loadingが正しく動作することを確認するために
  # 有効化することを推奨します。
  config.eager_load = ENV["CI"].present?

  # パフォーマンスのためにCache-Controlを設定してテスト用のパブリックファイルサーバーを設定します。
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # 完全なエラーレポートを表示し、キャッシュを無効にします。
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # 回復可能な例外には例外テンプレートをレンダリングし、他の例外には発生させます。
  config.action_dispatch.show_exceptions = :rescuable

  # テスト環境でリクエストフォージェリ保護を無効にします。
  config.action_controller.allow_forgery_protection = false

  # テスト環境でホスト認証を無効にします。
  config.middleware.delete ActionDispatch::HostAuthorization

  # アップロードされたファイルを一時ディレクトリのローカルファイルシステムに保存します。
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Action Mailerに実際の世界にメールを送信しないように伝えます。
  # :test配信方法は、送信されたメールをActionMailer::Base.deliveries配列に蓄積します。
  config.action_mailer.delivery_method = :test

  # 非推奨の通知をstderrに出力します。
  config.active_support.deprecation = :stderr

  # 許可されていない非推奨に対して例外を発生させます。
  config.active_support.disallowed_deprecation = :raise

  # Active Supportに許可しない非推奨メッセージを伝えます。
  config.active_support.disallowed_deprecation_warnings = []

  # 翻訳が見つからない場合にエラーを発生させます。
  # config.i18n.raise_on_missing_translations = true

  # レンダリングされたビューにファイル名を注釈付けします。
  # config.action_view.annotate_rendered_view_with_filenames = true

  # before_actionのonly/exceptオプションが欠落したアクションを参照する場合にエラーを発生させる
  config.action_controller.raise_on_missing_callback_actions = true
end
