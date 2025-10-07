# このファイルを変更したら、必ずサーバーを再起動してください。

# アプリケーション全体のコンテンツセキュリティポリシーを定義します。
# 詳細については、Railsアプリケーションのセキュリティガイドを参照してください：
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# Rails.application.configure do
#   config.content_security_policy do |policy|
#     policy.default_src :self, :https
#     policy.font_src    :self, :https, :data
#     policy.img_src     :self, :https, :data
#     policy.object_src  :none
#     policy.script_src  :self, :https
#     policy.style_src   :self, :https
#     # 違反レポートのURIを指定
#     # policy.report_uri "/csp-violation-report-endpoint"
#   end
#
#   # 許可されたimportmap、インラインスクリプト、インラインスタイルのセッションノンスを生成します。
#   config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
#   config.content_security_policy_nonce_directives = %w(script-src style-src)
#
#   # ポリシーを強制せずに違反をレポートします。
#   # config.content_security_policy_report_only = true
# end
