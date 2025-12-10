require 'simplecov'

# このファイルは'rails generate rspec:install'を実行するとspec/にコピーされます
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# 環境が本番環境の場合、データベースの切り詰めを防止します
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
# この行の下に追加のrequireを追加してください。この時点までRailsは読み込まれていません！

# spec/support/ およびそのサブディレクトリ内のカスタムマッチャー、マクロなどを含む
# サポート用のRubyファイルを必要とします。デフォルトでは`spec/**/*_spec.rb`に一致する
# ファイルはspecファイルとして実行されます。つまり、spec/support内の_spec.rbで終わる
# ファイルはrequireされると同時にspecとしても実行され、specが2回実行される原因となります。
# このglobに一致するファイルを_spec.rbで終わる名前にしないことを推奨します。
# このパターンはコマンドラインの--patternオプションまたは~/.rspec、.rspec、.rspec-localで設定できます。
#
# 以下の行は利便性のために提供されますが、supportディレクトリ内のすべてのファイルを
# 自動requireすることで起動時間を増加させる欠点があります。
# あるいは、個別の`*_spec.rb`ファイルで、必要なサポートファイルのみを手動でrequireしてください。
#
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# 保留中のマイグレーションをチェックし、テスト実行前に適用します。
# ActiveRecordを使用していない場合は、これらの行を削除できます。
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  # ActiveRecordまたはActiveRecord fixturesを使用していない場合は、この行を削除してください
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # ActiveRecordを使用していない場合、または各exampleをトランザクション内で実行したくない場合、
  # 以下の行を削除するか、trueの代わりにfalseを代入してください。
  config.use_transactional_fixtures = false

  # ActiveRecordサポートを完全に無効にするには、この行のコメントを解除してください。
  # config.use_active_record = false

  # RSpec Railsはファイルの場所に基づいて自動的に異なる動作をテストにミックスインできます。
  # 例えば、`spec/controllers`以下のspecで`get`や`post`を呼び出せるようにします。
  #
  # この動作を無効にするには以下の行を削除し、代わりにspecに明示的にタイプをタグ付けしてください。
  # 例:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # 利用可能なさまざまなタイプは機能で文書化されています。例えば：
  # https://rspec.info/features/6-0/rspec-rails
  config.infer_spec_type_from_file_location!

  # Rails gemからの行をバックトレースからフィルタリングします。
  config.filter_rails_from_backtrace!
  # 任意のgemも以下でフィルタリングできます：
  # config.filter_gems_from_backtrace("gem name")

  # Factory Bot設定
  config.include FactoryBot::Syntax::Methods

  # Devise integration helpers for request specs
  config.include Devise::Test::IntegrationHelpers, type: :request

  # Warden test mode for request and system specs
  config.before(:suite) do
    Warden.test_mode!
  end

  config.after(:each) do
    Warden.test_reset!
  end

  # CSRF protectionをリクエストテストで無効化
  config.before(:each, type: :request) do
    ActionController::Base.allow_forgery_protection = false
  end

  # System specs
  config.before(:each, type: :system) do
    driven_by :rack_test
    Capybara.default_host = "http://localhost"
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
    Capybara.default_host = "http://localhost"
  end

end
