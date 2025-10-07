# frozen_string_literal: true

# このファイルをまだ変更していない場合、以下の各設定オプションはデフォルト値に設定されています。
# 一部のオプションはコメントアウトされており、一部はコメントアウトされていないことに注意してください。
# コメントアウトされていない行は、アップグレード時に設定が破壊的な変更から保護することを目的としています。
# （つまり、将来のDeviseバージョンでデフォルト値が変更された場合に備えて）。
#
# このフックを使用してdevise mailer、warden hooksなどを設定します。
# これらの設定オプションの多くは、モデルで直接設定することができます。
Devise.setup do |config|
  # Deviseが使用する秘密鍵。Deviseはこの鍵を使用してランダムなトークンを生成します。
  # この鍵を変更すると、データベース内の既存の確認、パスワードリセット、アンロックトークンがすべて無効になります。
  # Deviseはデフォルトで`secret_key_base`を`secret_key`として使用します。
  # 以下で変更して独自の秘密鍵を使用することができます。
  # config.secret_key = '0dfff569ba3dc71e11dfb4d624814aad219dc96a8f752a922307df262cbdd20a99d9c9471d58847ce87c008a5abdfbd583e70f051cf5179acab9f2d2c3f81703'

  # ==> Controller configuration
  # deviseコントローラの親クラスを設定します。
  # config.parent_controller = 'DeviseController'

  # ==> Mailer Configuration
  # Devise::Mailerで表示されるメールアドレスを設定します。
  # 独自のmailerクラスを使用する場合、デフォルトの"from"パラメータで上書きされることに注意してください。
  config.mailer_sender = 'please-change-me-at-config-initializers-devise@example.com'

  # メール送信を担当するクラスを設定します。
  # config.mailer = 'Devise::Mailer'

  # メール送信を担当する親クラスを設定します。
  # config.parent_mailer = 'ActionMailer::Base'

  # ==> ORM configuration
  # ORMをロードして設定します。デフォルトで:active_recordと:mongoid（bson_ext推奨）をサポートします。
  # その他のORMは追加のgemとして利用可能かもしれません。
  require 'devise/orm/active_record'

  # ==> Configuration for any authentication mechanism
  # ユーザー認証時に使用するキーを設定します。デフォルトは:emailのみです。
  # [:username, :subdomain]を使用するように設定すると、ユーザー認証時に両方のパラメータが必要になります。
  # これらのパラメータは認証時にのみ使用され、セッションからの取得時には使用されないことに注意してください。
  # パーミッションが必要な場合は、before filterで実装する必要があります。
  # 値がブール値であるハッシュを提供することもでき、値が存在しない場合に認証を中止するかどうかを決定します。
  # config.authentication_keys = [:email]

  # 認証に使用されるリクエストオブジェクトからのパラメータを設定します。各エントリはリクエストメソッドで、
  # 自動的にfind_for_authenticationメソッドに渡され、モデル検索で考慮されます。
  # 例えば、:request_keysを[:subdomain]に設定すると、認証時に:subdomainが使用されます。
  # authentication_keysで言及されたのと同じ考慮事項がrequest_keysにも適用されます。
  # config.request_keys = []

  # 認証キーを大文字小文字を区別しないように設定します。
  # これらのキーはユーザー作成・変更時、および認証・検索時に小文字化されます。デフォルトは:emailです。
  config.case_insensitive_keys = [:email]

  # 認証キーの前後の空白を除去するように設定します。
  # これらのキーはユーザー作成・変更時、および認証・検索時に前後の空白が除去されます。デフォルトは:emailです。
  config.strip_whitespace_keys = [:email]

  # リクエスト.paramsを通じた認証が有効かどうかを設定します。デフォルトはtrueです。
  # 指定されたストラテジーのみでparams認証を有効にする配列に設定することができます。
  # 例えば、`config.params_authenticatable = [:database]`とすると、データベース認証でのみ有効になります。
  # config.params_authenticatable = true

  # HTTP Authを通じた認証が有効かどうかを設定します。デフォルトはfalseです。
  # 指定されたストラテジーのみでhttp認証を有効にする配列に設定することができます。
  # 例えば、`config.http_authenticatable = [:database]`とすると、データベース認証でのみ有効になります。
  # API専用アプリケーションで認証を「すぐに利用可能」にする場合、カスタムストラテジーを使用しない限り:databaseを有効にすることを推奨します。
  # サポートされるストラテジーは以下の通りです：
  # :database      = 認証キー + パスワードによる基本認証をサポート
  # config.http_authenticatable = false

  # AJAXリクエストに対して401ステータスコードを返すかどうかを設定します。デフォルトはtrueです。
  # config.http_authenticatable_on_xhr = true

  # Http Basic Authenticationで使用されるrealm。デフォルトは'Application'です。
  # config.http_authentication_realm = 'Application'

  # 確認、パスワード回復、その他のワークフローを、提供されたメールが正しいか間違っているかに関係なく同じように動作させます。
  # registerableには影響しません。
  # config.paranoid = true

  # デフォルトでDeviseはユーザーをセッションに保存します。このオプションを設定することで、
  # 特定のストラテジーに対して保存をスキップすることができます。
  # すべての認証パスで保存をスキップする場合、config/routes.rbの`devise_for`で
  # skip: :sessionsを渡してDeviseのsessionsコントローラへのルート生成を無効にすることを検討してください。
  config.skip_session_storage = [:http_auth]

  # デフォルトでDeviseは認証時にCSRFトークンをクリーンアップして、
  # CSRFトークン固定攻撃を防ぎます。つまり、AJAXリクエストを使用してサインイン・サインアップする場合、
  # サーバーから新しいCSRFトークンを取得する必要があります。このオプションは自己責任で無効にすることができます。
  # config.clean_up_csrf_token_on_authentication = true

  # falseの場合、Deviseはeager load時にルートのリロードを試みません。
  # これによりアプリの起動時間を短縮できますが、アプリケーションが起動時にDeviseマッピングをロードする必要がある場合、
  # アプリケーションが正しく起動しません。
  # config.reload_routes = true

  # ==> Configuration for :database_authenticatable
  # bcryptの場合、これはパスワードのハッシュ化コストで、デフォルトは12です。
  # 他のアルゴリズムを使用する場合、パスワードをハッシュ化する回数を設定します。
  # ハッシュ化されたパスワードで使用されるストレッチ回数は、ハッシュ化されたパスワードとともに保存されます。
  # これにより、既存のパスワードを無効化せずにストレッチ回数を変更することができます。
  #
  # テストではストレッチを1に制限すると、テストスイートの性能が劇的に向上します。
  # ただし、他の環境では10未満の値を使用しないことを強く推奨します。
  # bcrypt（デフォルトアルゴリズム）の場合、コストはストレッチ回数に応じて指数関数的に増加します
  # （例: 20の値はすでに非常に遅く、1回の計算で約60秒かかります）。
  config.stretches = Rails.env.test? ? 1 : 12

  # ハッシュ化されたパスワードを生成するためのpepperを設定します。
  # config.pepper = '250765b481e3daa3f3dea0484f008ed180bf85e7585a6f9cb1b745655845b52f5ddcb526f2837c840419b1fe11b295d0015459140810de742e7e2fee68f7eb2a'

  # ユーザーのメールアドレスが変更されたときに元のメールアドレスに通知を送信します。
  # config.send_email_changed_notification = false

  # ユーザーのパスワードが変更されたときに通知メールを送信します。
  # config.send_password_change_notification = false

  # ==> Configuration for :confirmable
  # ユーザーがアカウントを確認せずにウェブサイトにアクセスできる期間。
  # 例えば、2.daysに設定すると、ユーザーはアカウントを確認せずに2日間ウェブサイトにアクセスできますが、
  # 3日目にはアクセスがブロックされます。
  # nilに設定することもでき、その場合ユーザーはアカウントを確認せずにウェブサイトにアクセスできます。
  # デフォルトは0.daysで、ユーザーはアカウントを確認せずにウェブサイトにアクセスできません。
  # config.allow_unconfirmed_access_for = 2.days

  # ユーザーがアカウントを確認できる期間。その期間が過ぎるとトークンが無効になります。
  # 例えば、3.daysに設定すると、メール送信後3日以内にアカウントを確認できますが、
  # 4日目にはトークンではアカウントを確認できなくなります。
  # デフォルトはnilで、ユーザーがアカウントを確認するのに制限時間はありません。
  # config.confirm_within = 3.days

  # trueの場合、メールアドレスの変更を（初期アカウント確認とまったく同じ方法で）確認する必要があります。
  # 追加のunconfirmed_emailデータベースフィールドが必要です（マイグレーションを参照）。
  # 確認されるまで、新しいメールアドレスはunconfirmed_emailカラムに保存され、確認成功時にemailカラムにコピーされます。
  config.reconfirmable = true

  # アカウント確認時に使用するキーを定義します。
  # config.confirmation_keys = [:email]

  # ==> Configuration for :rememberable
  # ユーザーが再び資格情報を求められることなく記憶される時間。
  # config.remember_for = 2.weeks

  # ユーザーがサインアウトしたときにすべてのremember meトークンを無効化します。
  config.expire_all_remember_me_on_sign_out = true

  # trueの場合、cookie経由で記憶されたときにユーザーの記憶期間を延長します。
  # config.extend_remember_period = false

  # 作成されたcookieに渡されるオプション。例えば、secure: trueを設定してSSL専用cookieを強制できます。
  # config.rememberable_options = {}

  # ==> Configuration for :validatable
  # パスワードの長さの範囲。
  config.password_length = 6..128

  # メールアドレスの形式を検証するための正規表現。文字列に@が1つだけ存在することを単純に確認します。
  # これは主にユーザーにフィードバックを与えるためのもので、メールアドレスの有効性を確認するものではありません。
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # ==> Configuration for :timeoutable
  # アクティビティなしでユーザーセッションをタイムアウトさせる時間。この時間が経過すると、
  # ユーザーに資格情報が再び求められます。デフォルトは30分です。
  # config.timeout_in = 30.minutes

  # ==> Configuration for :lockable
  # アカウントをロックするために使用するストラテジーを定義します。
  # :failed_attempts = サインイン失敗回数後にアカウントをロック
  # :none            = ロックストラテジーなし。自分でロック処理を実装する必要があります。
  # config.lock_strategy = :failed_attempts

  # アカウントのロック・ロック解除時に使用するキーを定義します。
  # config.unlock_keys = [:email]

  # アカウントのロック解除に使用するストラテジーを定義します。
  # :email = ユーザーのメールアドレスにアンロックリンクを送信
  # :time  = 一定時間経過後にログインを再有効化（下記の:unlock_inを参照）
  # :both  = 両方のストラテジーを有効化
  # :none  = アンロックストラテジーなし。自分でアンロック処理を実装する必要があります。
  # config.unlock_strategy = :both

  # lock_strategyがfailed attemptsの場合、アカウントをロックする前の認証試行回数。
  # config.maximum_attempts = 20

  # unlock_strategyで:timeが有効な場合、アカウントをロック解除する時間間隔。
  # config.unlock_in = 1.hour

  # アカウントがロックされる前の最後の試行で警告を表示します。
  # config.last_attempt_warning = true

  # ==> Configuration for :recoverable
  #
  # アカウントのパスワード回復時に使用するキーを定義します。
  # config.reset_password_keys = [:email]

  # パスワードリセットキーでパスワードをリセットできる時間間隔。
  # あまり短い間隔を設定すると、ユーザーがパスワードを変更する時間がなくなります。
  config.reset_password_within = 6.hours

  # falseの場合、パスワードリセット後にユーザーを自動的にサインインしません。
  # デフォルトはtrueで、リセット後にユーザーが自動的にサインインします。
  # config.sign_in_after_reset_password = true

  # ==> Configuration for :encryptable
  # bcrypt（デフォルト）以外のハッシュ化または暗号化アルゴリズムを使用できるようにします。
  # :sha1、:sha512、または他の認証ツールのアルゴリズムを使用できます。例えば、
  # :clearance_sha1、:authlogic_sha512（この場合、上記のstretchesを20に設定）、
  # :restful_authentication_sha1（この場合、stretchesを10に設定し、REST_AUTH_SITE_KEYをpepperにコピー）。
  #
  # bcrypt以外を使用する場合、`devise-encryptable` gemが必要です。
  # config.encryptor = :sha512

  # ==> Scopes configuration
  # スコープ付きビューをオンにします。"sessions/new"をレンダリングする前に、
  # まず"users/sessions/new"を確認します。デフォルトのビューを使用している場合のみ遅くなるため、デフォルトでオフです。
  # config.scoped_views = false

  # Wardenに与えられるデフォルトスコープを設定します。デフォルトではルートで宣言された最初のdeviseロール（通常:user）です。
  # config.default_scope = :user

  # この設定をfalseにすると、/users/sign_outが現在のスコープのみをサインアウトします。
  # デフォルトでDeviseはすべてのスコープをサインアウトします。
  # config.sign_out_all_scopes = true

  # ==> Navigation configuration
  # ナビゲーションとして扱われるフォーマットをリストアップします。
  # :htmlのようなフォーマットは、ユーザーがアクセス権を持たない場合にサインインページにリダイレクトしますが、
  # :xmlや:jsonのようなフォーマットは401を返します。
  #
  # :iphoneや:mobileのような追加のナビゲーションフォーマットがある場合、
  # ナビゲーションフォーマットリストに追加してください。
  #
  # 下記の"*/*"はInternet Explorerのリクエストに一致させるために必要です。
  # config.navigational_formats = ['*/*', :html, :turbo_stream]

  # リソースをサインアウトするために使用されるデフォルトのHTTPメソッド。デフォルトは:deleteです。
  config.sign_out_via = :delete

  # ==> OmniAuth
  # 新しいOmniAuthプロバイダを追加します。設定方法の詳細についてはwikiを確認してください。
  # config.omniauth :github, 'APP_ID', 'APP_SECRET', scope: 'user,public_repo'

  # ==> Warden configuration
  # Deviseでサポートされていない他のストラテジーを使用する場合、またはfailure appを変更する場合、
  # config.wardenブロック内で設定することができます。
  #
  # config.warden do |manager|
  #   manager.intercept_401 = false
  #   manager.default_strategies(scope: :user).unshift :some_external_strategy
  # end

  # ==> Mountable engine configurations
  # engine内でDeviseを使用する場合、そのengineがマウント可能である場合、いくつかの追加設定を考慮する必要があります。
  # engineが以下のようにマウントされていると仮定すると、以下のオプションが利用可能です：
  #
  #     mount MyEngine, at: '/my_engine'
  #
  # 上記の例で`devise_for`を呼び出したrouterは以下のようになります：
  # config.router_name = :my_engine
  #
  # OmniAuthを使用する場合、Deviseは自動的にOmniAuthパスを設定できないため、
  # 手動で設定する必要があります。usersスコープの場合、以下のようになります：
  # config.omniauth_path_prefix = '/my_engine/users/auth'

  # ==> Hotwire/Turbo configuration
  # Hotwire/TurboでDeviseを使用する場合、エラーレスポンスと一部のリダイレクトのhttpステータスは
  # 以下のものと一致する必要があります。既存のアプリでのDeviseのデフォルトは
  # `200 OK`と`302 Found`ですが、新しいアプリはHotwire/Turboの動作に一致するこれらの新しいデフォルトで生成されます。
  # 注意: これらは将来のDeviseバージョンで新しいデフォルトになるかもしれません。
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  # ==> Configuration for :registerable

  # falseの場合、パスワード変更後にユーザーを自動的にサインインしません。
  # デフォルトはtrueで、パスワード変更後にユーザーが自動的にサインインします。
  # config.sign_in_after_change_password = true
end