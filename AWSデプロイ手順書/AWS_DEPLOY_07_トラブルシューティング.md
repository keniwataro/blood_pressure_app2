# AWSデプロイ手順 Part 7: トラブルシューティング

## 目次
1. よくある問題と解決方法
2. ログの確認方法
3. デバッグ手順
4. ロールバック方法

---

## 1. よくある問題と解決方法

### 問題1: ALBにアクセスしても503エラーが表示される

**原因:**
- ECSタスクが起動していない
- ヘルスチェックが失敗している
- セキュリティグループの設定ミス

**解決方法:**

1. **ECSタスクの状態確認**
```bash
aws ecs describe-services \
  --cluster blood-pressure-cluster \
  --services blood-pressure-service \
  --region ap-northeast-1
```

2. **タスクのログ確認**
   - CloudWatchコンソール → ロググループ → `/ecs/blood-pressure-task`
   - エラーメッセージを確認

3. **ヘルスチェック確認**
   - EC2コンソール → ターゲットグループ → `blood-pressure-tg`
   - ターゲットのステータスが「healthy」か確認

4. **セキュリティグループ確認**
   - ALB SG: インバウンド 80番ポート許可
   - ECS SG: インバウンド 3000番ポート（ソース: ALB SG）許可

---

### 問題2: データベース接続エラー

**エラーメッセージ例:**
```
PG::ConnectionBad: could not connect to server
```

**解決方法:**

1. **RDSエンドポイント確認**
```bash
aws rds describe-db-instances \
  --db-instance-identifier blood-pressure-db \
  --region ap-northeast-1 \
  --query 'DBInstances[0].Endpoint.Address'
```

2. **環境変数確認**
   - ECSタスク定義で `DATABASE_HOST` が正しいか確認

3. **セキュリティグループ確認**
   - RDS SG: インバウンド 5432番ポート（ソース: ECS SG）許可

4. **接続テスト**
```bash
# ECSタスク内で実行
aws ecs execute-command \
  --cluster blood-pressure-cluster \
  --task <タスクID> \
  --container rails-app \
  --interactive \
  --command "/bin/bash" \
  --region ap-northeast-1

# コンテナ内で
apt-get update && apt-get install -y postgresql-client
psql -h $DATABASE_HOST -U $DATABASE_USERNAME -d $DATABASE_NAME
```

---

### 問題3: SECRET_KEY_BASEエラー

**エラーメッセージ例:**
```
ArgumentError: Missing `secret_key_base` for 'production' environment
```

**解決方法:**

1. **SECRET_KEY_BASEの生成**
```bash
docker-compose exec web rails secret
```

2. **ECSタスク定義に追加**
   - ECSコンソール → タスク定義 → 新しいリビジョンを作成
   - 環境変数に `SECRET_KEY_BASE` を追加
   - サービスを更新して新しいタスク定義を使用

---

### 問題4: アセット（CSS/JS）が読み込まれない

**原因:**
- アセットがプリコンパイルされていない
- S3設定が正しくない

**解決方法:**

1. **アセットプリコンパイル確認**
```bash
# Dockerイメージビルド時に実行されているか確認
docker build -f Dockerfile.production -t blood-pressure-app:latest .
```

2. **production.rb設定確認**
```ruby
config.assets.compile = false
config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
```

3. **環境変数追加**
   - ECSタスク定義に `RAILS_SERVE_STATIC_FILES=true` を追加

---

### 問題5: マイグレーションが実行されていない

**エラーメッセージ例:**
```
ActiveRecord::StatementInvalid: PG::UndefinedTable: ERROR: relation "users" does not exist
```

**解決方法:**

1. **マイグレーション実行**
```bash
# タスクIDを取得
TASK_ARN=$(aws ecs list-tasks \
  --cluster blood-pressure-cluster \
  --service-name blood-pressure-service \
  --region ap-northeast-1 \
  --query 'taskArns[0]' \
  --output text)

# コンテナに接続
aws ecs execute-command \
  --cluster blood-pressure-cluster \
  --task $TASK_ARN \
  --container rails-app \
  --interactive \
  --command "/bin/bash" \
  --region ap-northeast-1

# マイグレーション実行
bundle exec rails db:migrate RAILS_ENV=production
bundle exec rails db:seed RAILS_ENV=production
```

---

### 問題6: ECS Execが使えない

**エラーメッセージ例:**
```
An error occurred (InvalidParameterException) when calling the ExecuteCommand operation
```

**解決方法:**

1. **ECS Execの有効化**
```bash
aws ecs update-service \
  --cluster blood-pressure-cluster \
  --service blood-pressure-service \
  --enable-execute-command \
  --region ap-northeast-1
```

2. **タスクロールにポリシー追加**
   - IAMコンソール → ロール → `ecsTaskExecutionRole`
   - 以下のポリシーを追加:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    }
  ]
}
```

3. **サービスの再起動**
```bash
aws ecs update-service \
  --cluster blood-pressure-cluster \
  --service blood-pressure-service \
  --force-new-deployment \
  --region ap-northeast-1
```

---

## 2. ログの確認方法

### 2-1. CloudWatch Logsでアプリケーションログ確認
1. AWSコンソールで「CloudWatch」を検索
2. 左メニュー「ロググループ」
3. `/ecs/blood-pressure-task` をクリック
4. 最新のログストリームをクリック
5. エラーメッセージを検索

### 2-2. AWS CLIでログ確認
```bash
# 最新のログを表示
aws logs tail /ecs/blood-pressure-task --follow --region ap-northeast-1

# エラーのみフィルタ
aws logs filter-log-events \
  --log-group-name /ecs/blood-pressure-task \
  --filter-pattern "ERROR" \
  --region ap-northeast-1
```

### 2-3. ECSタスクのイベント確認
```bash
aws ecs describe-services \
  --cluster blood-pressure-cluster \
  --services blood-pressure-service \
  --region ap-northeast-1 \
  --query 'services[0].events[0:10]'
```

---

## 3. デバッグ手順

### 3-1. タスクが起動しない場合

1. **タスク定義の確認**
```bash
aws ecs describe-task-definition \
  --task-definition blood-pressure-task \
  --region ap-northeast-1
```

2. **停止したタスクの理由確認**
```bash
aws ecs describe-tasks \
  --cluster blood-pressure-cluster \
  --tasks <タスクARN> \
  --region ap-northeast-1 \
  --query 'tasks[0].stoppedReason'
```

3. **イメージプル確認**
   - ECRリポジトリにイメージが存在するか確認
   - タスク実行ロールにECRアクセス権限があるか確認

### 3-2. ヘルスチェック失敗の場合

1. **ターゲットグループのヘルスチェック設定確認**
   - パス: `/`
   - ポート: 3000
   - プロトコル: HTTP

2. **Railsアプリケーションの起動確認**
```bash
# コンテナ内で
curl http://localhost:3000
```

3. **ヘルスチェックパスの変更**
   - Railsに専用のヘルスチェックエンドポイントを作成
   - `config/routes.rb`:
```ruby
get '/health', to: proc { [200, {}, ['OK']] }
```

---

## 4. ロールバック方法

### 4-1. 以前のタスク定義に戻す

1. **タスク定義のリビジョン確認**
```bash
aws ecs list-task-definitions \
  --family-prefix blood-pressure-task \
  --region ap-northeast-1
```

2. **サービスを以前のリビジョンに更新**
```bash
aws ecs update-service \
  --cluster blood-pressure-cluster \
  --service blood-pressure-service \
  --task-definition blood-pressure-task:1 \
  --region ap-northeast-1
```

### 4-2. 以前のDockerイメージに戻す

1. **ECRのイメージタグ確認**
```bash
aws ecr list-images \
  --repository-name blood-pressure-app \
  --region ap-northeast-1
```

2. **タスク定義を更新して以前のイメージを指定**
   - ECSコンソール → タスク定義 → 新しいリビジョンを作成
   - イメージURIを以前のタグに変更
   - サービスを更新

---

## 5. パフォーマンス問題

### 5-1. 遅いレスポンス

**確認項目:**
1. **RDSのCPU/メモリ使用率**
   - CloudWatch → RDS メトリクス
   - 高い場合はインスタンスタイプをアップグレード

2. **N+1クエリの確認**
   - Railsログで遅いクエリを確認
   - `bullet` gemを使用して検出

3. **接続プール設定**
   - `config/database.yml`:
```yaml
production:
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

### 5-2. メモリ不足

**解決方法:**
1. **タスク定義のメモリを増やす**
   - 1GB → 2GB に変更

2. **Pumaワーカー数の調整**
   - `config/puma.rb`:
```ruby
workers ENV.fetch("WEB_CONCURRENCY") { 2 }
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count
```

---

## 6. コスト最適化

### 6-1. 不要なリソースの削除
```bash
# 使用していないECRイメージの削除
aws ecr batch-delete-image \
  --repository-name blood-pressure-app \
  --image-ids imageTag=old-tag \
  --region ap-northeast-1

# 古いログの削除
aws logs delete-log-group \
  --log-group-name /ecs/old-task \
  --region ap-northeast-1
```

### 6-2. RDSのスケールダウン
開発環境では:
- インスタンスタイプ: db.t3.micro
- ストレージ: 20GB
- 自動バックアップ: 1日

---

## サポート

問題が解決しない場合:
1. CloudWatchログを確認
2. AWSサポートに問い合わせ
3. GitHubのissueを作成

---

## 参考リンク

- [AWS ECS トラブルシューティング](https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/troubleshooting.html)
- [Rails本番環境設定](https://guides.rubyonrails.org/configuring.html#configuring-a-database)
- [AWS Well-Architected Framework](https://aws.amazon.com/jp/architecture/well-architected/)
