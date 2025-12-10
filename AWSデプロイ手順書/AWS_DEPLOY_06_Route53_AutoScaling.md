# AWSデプロイ手順 Part 6: Route53・AutoScaling設定

## 目次
1. Route53でドメイン設定
2. AutoScaling設定
3. CloudWatch監視設定
4. 本番環境の最終調整

---

## 1. Route53でドメイン設定（オプション）

### 1-1. ドメインの取得（既に持っている場合はスキップ）
1. AWSコンソールで「Route 53」を検索して開く
2. 左メニュー「ドメイン」→「ドメインの登録」
3. 希望のドメイン名を検索して購入

### 1-2. ホストゾーンの作成
1. 左メニュー「ホストゾーン」→「ホストゾーンの作成」
2. **ドメイン名**: 取得したドメイン名（例: `example.com`）
3. **タイプ**: パブリックホストゾーン
4. 「ホストゾーンの作成」

### 1-3. ALBへのレコード作成
1. 作成したホストゾーンをクリック
2. 「レコードを作成」をクリック
3. 以下を入力:
   - **レコード名**: 空欄（ルートドメイン）または `www`
   - **レコードタイプ**: A
   - **エイリアス**: 有効
   - **トラフィックのルーティング先**: 
     - Application Load Balancerとclassic Load Balancerへのエイリアス
     - リージョン: アジアパシフィック（東京）
     - ロードバランサー: `blood-pressure-alb`を選択
4. 「レコードを作成」

**DNS伝播には最大48時間かかる場合があります。**

---

## 2. AutoScaling設定

### 2-1. Auto Scalingの有効化
1. ECSコンソールで `blood-pressure-cluster` を開く
2. `blood-pressure-service` をクリック
3. 「Auto Scaling」タブ→「Auto Scalingの設定を更新」

### 2-2. スケーリングポリシーの設定
1. **サービスのAuto Scaling**:
   - **最小タスク数**: 2
   - **必要なタスク数**: 2
   - **最大タスク数**: 10

2. **スケーリングポリシー**:
   - 「ターゲット追跡スケーリングポリシーを追加」をクリック
   
3. **CPU使用率ベースのスケーリング**:
   - **ポリシー名**: `cpu-scaling-policy`
   - **ECSサービスメトリクス**: ECSServiceAverageCPUUtilization
   - **ターゲット値**: 70
   - **スケールアウトクールダウン期間**: 300秒
   - **スケールインクールダウン期間**: 300秒

4. 「ターゲット追跡スケーリングポリシーを追加」をクリック

5. **メモリ使用率ベースのスケーリング**:
   - **ポリシー名**: `memory-scaling-policy`
   - **ECSサービスメトリクス**: ECSServiceAverageMemoryUtilization
   - **ターゲット値**: 80
   - **スケールアウトクールダウン期間**: 300秒
   - **スケールインクールダウン期間**: 300秒

6. 「保存」をクリック

---

## 3. CloudWatch監視設定

### 3-1. CloudWatchダッシュボードの作成
1. AWSコンソールで「CloudWatch」を検索して開く
2. 左メニュー「ダッシュボード」→「ダッシュボードの作成」
3. **ダッシュボード名**: `blood-pressure-dashboard`
4. 「ダッシュボードの作成」

### 3-2. ウィジェットの追加

#### ECS CPU使用率
1. 「ウィジェットを追加」→「折れ線」
2. **メトリクス**:
   - ECS → クラスターメトリクス
   - `blood-pressure-cluster` の `CPUUtilization` を選択
3. 「ウィジェットの作成」

#### ECS メモリ使用率
1. 「ウィジェットを追加」→「折れ線」
2. **メトリクス**:
   - ECS → クラスターメトリクス
   - `blood-pressure-cluster` の `MemoryUtilization` を選択
3. 「ウィジェットの作成」

#### ALB リクエスト数
1. 「ウィジェットを追加」→「折れ線」
2. **メトリクス**:
   - ApplicationELB → ロードバランサー別
   - `blood-pressure-alb` の `RequestCount` を選択
3. 「ウィジェットの作成」

#### RDS CPU使用率
1. 「ウィジェットを追加」→「折れ線」
2. **メトリクス**:
   - RDS → DBインスタンス別
   - `blood-pressure-db` の `CPUUtilization` を選択
3. 「ウィジェットの作成」

### 3-3. アラームの設定

#### ECS高CPU使用率アラーム
1. 左メニュー「アラーム」→「アラームの作成」
2. 「メトリクスの選択」
3. ECS → クラスターメトリクス → `blood-pressure-cluster` の `CPUUtilization`
4. **条件**:
   - **しきい値のタイプ**: 静的
   - **条件**: より大きい
   - **しきい値**: 80
5. **アラーム名**: `blood-pressure-high-cpu`
6. 「アラームの作成」

#### RDS高CPU使用率アラーム
1. 「アラームの作成」
2. RDS → DBインスタンス別 → `blood-pressure-db` の `CPUUtilization`
3. **条件**:
   - **しきい値のタイプ**: 静的
   - **条件**: より大きい
   - **しきい値**: 80
4. **アラーム名**: `blood-pressure-db-high-cpu`
5. 「アラームの作成」

---

## 4. 本番環境の最終調整

### 4-1. Rails設定ファイルの更新

#### config/environments/production.rb
以下の設定を確認・更新:

```ruby
# S3を使用する設定
config.active_storage.service = :amazon

# ホスト設定
config.hosts << "blood-pressure-alb-xxxxxxxxxx.ap-northeast-1.elb.amazonaws.com"
config.hosts << "example.com" # 独自ドメインを使用する場合
```

#### config/storage.yml
S3設定を追加:

```yaml
amazon:
  service: S3
  access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
  region: ap-northeast-1
  bucket: blood-pressure-app-assets-20240115
```

### 4-2. 環境変数の追加
ECSタスク定義を更新して以下の環境変数を追加:

| キー | 値 |
|------|-----|
| RAILS_SERVE_STATIC_FILES | true |
| RAILS_MASTER_KEY | （config/master.keyの内容） |

### 4-3. イメージの再ビルドとデプロイ
```bash
# イメージのビルド
docker build -f Dockerfile.production -t blood-pressure-app:latest .

# タグ付け
docker tag blood-pressure-app:latest 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/blood-pressure-app:latest

# プッシュ
docker push 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/blood-pressure-app:latest

# ECSサービスの強制デプロイ
aws ecs update-service \
  --cluster blood-pressure-cluster \
  --service blood-pressure-service \
  --force-new-deployment \
  --region ap-northeast-1
```

---

## 5. セキュリティ強化（推奨）

### 5-1. HTTPSの設定（ACM証明書）
1. AWSコンソールで「Certificate Manager」を検索
2. 「証明書をリクエスト」
3. **証明書タイプ**: パブリック証明書
4. **ドメイン名**: `example.com`, `*.example.com`
5. **検証方法**: DNS検証
6. Route 53でCNAMEレコードを作成して検証
7. ALBにHTTPSリスナーを追加（ポート443）

### 5-2. WAFの設定（オプション）
1. AWSコンソールで「WAF & Shield」を検索
2. Web ACLを作成してALBに関連付け
3. SQLインジェクション、XSSなどの保護ルールを追加

---

## 完了！

これでAWSへのデプロイが完了しました。

### 確認事項チェックリスト
- [ ] アプリケーションにアクセスできる
- [ ] ログインできる
- [ ] 血圧記録の登録・閲覧ができる
- [ ] グラフが表示される
- [ ] Auto Scalingが動作する
- [ ] CloudWatchでメトリクスが確認できる

### トラブルシューティング
問題が発生した場合は「AWS_DEPLOY_07_トラブルシューティング.md」を参照してください。
