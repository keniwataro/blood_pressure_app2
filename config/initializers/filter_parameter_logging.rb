# このファイルを変更したら、必ずサーバーを再起動してください。

# ログファイルからフィルタリングされるパラメータを設定します（例: passwはpasswordに部分一致）。
# これを使用して機密情報の拡散を制限します。
# サポートされる表記法と動作については、ActiveSupport::ParameterFilterドキュメントを参照してください。
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn
]
