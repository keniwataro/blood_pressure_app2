require_relative "boot"

require "rails/all"

# Gemfileに記載されているgemを必要に応じて読み込みます。
# :test、:development、または:productionに限定したgemも含まれます。
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # 元々生成されたRailsバージョンのデフォルト設定を初期化します。
    config.load_defaults 7.1

    # Turboを完全に無効化
    config.turbo.signed_stream_verifier_key = nil
    config.turbo.draw_routes = false
    config.turbo.mount_path = nil

    # .rbファイルを含まない他のlibサブディレクトリ、またはリロードまたはeager loadしないものを
    # ignoreリストに追加してください。
    # 一般的なものはtemplates、generators、またはmiddlewareなどです。
    config.autoload_lib(ignore: %w(assets tasks))

    # アプリケーション、エンジン、およびrailtiesの設定はここに記述します。
    #
    # これらの設定は、後で処理されるconfig/environments内のファイルを使用して
    # 特定の環境で上書きすることができます。
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # 国際化設定
    config.i18n.default_locale = :ja
    config.time_zone = 'Tokyo'
  end
end
