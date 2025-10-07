# この設定ファイルはPumaによって評価されます。ここで呼び出されるトップレベルのメソッドは
# Pumaの設定DSLの一部です。DSLによって提供されるメソッドの詳細については、
# https://puma.io/puma/Puma/DSL.html を参照してください。

# Pumaは内部スレッドプールから各リクエストをスレッドで処理できます。
# `threads`メソッドの設定には最小値と最大値の2つの数値が必要です。
# スレッドプールを使用するライブラリはすべて、Pumaに指定された最大値に一致するように
# 設定する必要があります。デフォルトでは最小値と最大値ともに5スレッドに設定されており、
# これはActive Recordのデフォルトスレッドサイズと一致します。
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

rails_env = ENV.fetch("RAILS_ENV") { "development" }

if rails_env == "production"
  # プロセスごとに1つ以上のスレッドを実行する場合、ワーカー数は本番環境での
  # プロセッサ数（CPUコア数）と等しくなければなりません。
  #
  # デフォルトは1に設定されています。なぜなら、利用可能なCPUコア数を確実に
  # 検出することが不可能だからです。プロセッサ数に一致するように
  # `WEB_CONCURRENCY`環境変数を設定してください。
  worker_count = Integer(ENV.fetch("WEB_CONCURRENCY") { 1 })
  if worker_count > 1
    workers worker_count
  else
    preload_app!
  end
end
# 開発環境でワーカーを終了させる前にPumaが待機する`worker_timeout`しきい値を指定します。
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# リクエストを受信するためにPumaがリッスンする`port`を指定します。デフォルトは3000です。
port ENV.fetch("PORT") { 3000 }

# Pumaが実行される`environment`を指定します。
environment rails_env

# Pumaが使用する`pidfile`を指定します。
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# `bin/rails restart`コマンドでpumaを再起動できるようにします。
plugin :tmp_restart
