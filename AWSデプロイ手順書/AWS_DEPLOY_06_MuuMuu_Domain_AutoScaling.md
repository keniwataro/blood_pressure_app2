# AWSデプロイ手順 Part 6: ムームードメイン + Route 53・AutoScaling設定

## 目次
1. Route 53でホストゾーン作成
2. ムームードメインでネームサーバー変更
3. Route 53でALBレコード作成
4. AutoScaling設定
5. CloudWatch監視設定
6. 本番環境の最終調整

---

## 1. Route 53でホストゾーン作成

### 前提条件
- ムームードメインでドメインを取得済み（例: `example.com`）
- ALBが作成済み

### 1-1. ホストゾーンの作成
1. AWSコンソールで「Route 53」を検索して開く
2. 左メニュー「ホストゾーン」→「ホストゾーンの作成」
3. 以下を入力:
   - **ドメイン名**: ムームードメインで取得したドメイン名（例: `example.com`）
   - **タイプ**: パブリックホストゾーン
4. 「ホストゾーンの作成」をクリック

### 1-2. ネームサーバー情報の確認
1. 作成したホストゾーンをクリック
2. **NSレコード**（タイプがNS）の値を確認
3. 4つのネームサーバーが表示される（例）:
   ```
   ns-123.awsdns-12.com
   ns-456.awsdns-45.net
   ns-789.awsdns-78.org
   ns-012.awsdns-01.co.uk
   ```
4. これらをメモまたはコピー（次のステップで使用）

---

## 2. ムームードメインでネームサーバー変更

### 2-1. ムームードメインのコントロールパネルにログイン
1. https://muumuu-domain.com/ にアクセス
2. ログインIDとパスワードを入力してログイン

### 2-2. ネームサーバー設定変更
1. 「コントロールパネル」→「ドメイン管理」→「ドメイン操作」
2. 対象ドメインの「ネームサーバ設定変更」をクリック
3. 「GMOペパボ以外のネームサーバを使用する」を選択
4. Route 53で確認した4つのネームサーバーを入力:
   - **ネームサーバ1**: `ns-123.awsdns-12.com`
   - **ネームサーバ2**: `ns-456.awsdns-45.net`
   - **ネームサーバ3**: `ns-789.awsdns-78.org`
   - **ネームサーバ4**: `ns-012.awsdns-01.co.uk`
5. 「ネームサーバ設定変更」ボタンをクリック

### 2-3. 設定の確認
**ネームサーバーの変更が反映されるまで数時間〜48時間かかる場合があります。**

#### コマンドラインで確認
```bash
# ネームサーバーの確認
nslookup -type=NS example.com

# example.comの部分を自分のドメインに変更
# Route 53のネームサーバーが表示されればOK
```

---

## 3. Route 53でALBレコード作成

### 3-1. ALBのDNS名を確認
1. AWSコンソールで「EC2」→「ロードバランサー」を開く
2. `blood-pressure-alb` を選択
3. **DNS名**を確認（例: `blood-pressure-alb-123456789.ap-northeast-1.elb.amazonaws.com`）

### 3-2. Aレコード（エイリアス）の作成
1. Route 53のホストゾーン画面に戻る
2. 作成したホストゾーン（`example.com`）をクリック
3. 「レコードを作成」をクリック

#### ルートドメイン（example.com）のレコード
4. 以下を入力:
   - **レコード名**: 空欄（ルートドメイン）
   - **レコードタイプ**: A
   - **エイリアス**: 有効にする（トグルをON）
   - **トラフィックのルーティング先**: 
     - 「Application Load BalancerとClassic Load Balancerへのエイリアス」を選択
     - **リージョン**: アジアパシフィック（東京）ap-northeast-1
     - **ロードバランサー**: `blood-pressure-alb` を選択
   - **ルーティングポリシー**: シンプルルーティング
5. 「レコードを作成」をクリック

#### wwwサブドメイン（www.example.com）のレコード
6. 再度「レコードを作成」をクリック
7. 以下を入力:
   - **レコード名**: `www`
   - **レコードタイプ**: A
   - **エイリアス**: 有効にする
   - **トラフィックのルーティング先**: 
     - 「Application Load BalancerとClassic Load Balancerへのエイリアス」を選択
     - **リージョン**: アジアパシフィック（東京）ap-northeast-1
     - **ロードバランサー**: `blood-pressure-alb` を選択
8. 「レコードを作成」をクリック

### 3-3. DNS設定の確認

#### コマンドラインで確認
```bash
# ルートドメインの確認
nslookup example.com

# wwwサブドメインの確認
nslookup www.example.com
```

#### ブラウザで確認
```
http://example.com
http://www.example.com
```

---

## 4. AutoScaling設定

### 4-1. タスク数の設定
1. ECSコンソールで `blood-pressure-cluster` を開く
2. `blood-pressure-service` をクリック
3. 「サービスの自動スケーリング」セクションの「タスクの数を設定」ボタンをクリック
4. 「サービスの自動スケーリングを使用して、サービスの望ましいタスク数を調整します」のチェックボックスをオンにする
5. 以下を入力:
   - **タスクの最小数**: 2
   - **最大**: 10
6. 「保存」をクリック

### 4-2. Application Auto Scalingの設定（AWS CLI使用）

#### 前提条件
AWS CLIがインストールされ、認証情報が設定されていること

#### スケーラブルターゲットの登録
```bash
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/blood-pressure-cluster/blood-pressure-service \
  --min-capacity 2 \
  --max-capacity 10 \
  --region ap-northeast-1
```

#### CPU使用率ベースのスケーリングポリシー

**1. cpu-scaling-policy.jsonファイルを作成**
```bash
cat > cpu-scaling-policy.json << 'EOF'
{
  "TargetValue": 70.0,
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
  },
  "ScaleOutCooldown": 300,
  "ScaleInCooldown": 300
}
EOF
```

**2. スケーリングポリシーを適用**
```bash
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/blood-pressure-cluster/blood-pressure-service \
  --policy-name cpu-scaling-policy \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration file://cpu-scaling-policy.json \
  --region ap-northeast-1
```

#### メモリ使用率ベースのスケーリングポリシー

**1. memory-scaling-policy.jsonファイルを作成**
```bash
cat > memory-scaling-policy.json << 'EOF'
{
  "TargetValue": 80.0,
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ECSServiceAverageMemoryUtilization"
  },
  "ScaleOutCooldown": 300,
  "ScaleInCooldown": 300
}
EOF
```

**2. スケーリングポリシーを適用**
```bash
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/blood-pressure-cluster/blood-pressure-service \
  --policy-name memory-scaling-policy \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration file://memory-scaling-policy.json \
  --region ap-northeast-1
```

### 4-3. 設定の確認

#### スケーラブルターゲットの確認
```bash
aws application-autoscaling describe-scalable-targets \
  --service-namespace ecs \
  --resource-ids service/blood-pressure-cluster/blood-pressure-service \
  --region ap-northeast-1
```

**確認項目:**
- ✅ `MinCapacity`: 2（最小タスク数）
- ✅ `MaxCapacity`: 10（最大タスク数）
- ✅ `ResourceId`: service/blood-pressure-cluster/blood-pressure-service
- ✅ `ScalableDimension`: ecs:service:DesiredCount

**正常な出力例:**
```json
{
    "ScalableTargets": [
        {
            "ServiceNamespace": "ecs",
            "ResourceId": "service/blood-pressure-cluster/blood-pressure-service",
            "ScalableDimension": "ecs:service:DesiredCount",
            "MinCapacity": 2,
            "MaxCapacity": 10,
            "RoleARN": "arn:aws:iam::123456789012:role/aws-service-role/...",
            "CreationTime": "2024-01-15T12:00:00.000000+09:00"
        }
    ]
}
```

#### スケーリングポリシーの確認
```bash
aws application-autoscaling describe-scaling-policies \
  --service-namespace ecs \
  --resource-id service/blood-pressure-cluster/blood-pressure-service \
  --region ap-northeast-1
```

**確認項目:**
- ✅ 2つのポリシーが存在する（cpu-scaling-policy と memory-scaling-policy）
- ✅ `PolicyType`: TargetTrackingScaling
- ✅ CPUポリシーの `TargetValue`: 70.0
- ✅ メモリポリシーの `TargetValue`: 80.0
- ✅ `ScaleOutCooldown`: 300秒
- ✅ `ScaleInCooldown`: 300秒

**正常な出力例:**
```json
{
    "ScalingPolicies": [
        {
            "PolicyName": "cpu-scaling-policy",
            "ServiceNamespace": "ecs",
            "ResourceId": "service/blood-pressure-cluster/blood-pressure-service",
            "ScalableDimension": "ecs:service:DesiredCount",
            "PolicyType": "TargetTrackingScaling",
            "TargetTrackingScalingPolicyConfiguration": {
                "TargetValue": 70.0,
                "PredefinedMetricSpecification": {
                    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
                },
                "ScaleOutCooldown": 300,
                "ScaleInCooldown": 300
            }
        },
        {
            "PolicyName": "memory-scaling-policy",
            "ServiceNamespace": "ecs",
            "ResourceId": "service/blood-pressure-cluster/blood-pressure-service",
            "ScalableDimension": "ecs:service:DesiredCount",
            "PolicyType": "TargetTrackingScaling",
            "TargetTrackingScalingPolicyConfiguration": {
                "TargetValue": 80.0,
                "PredefinedMetricSpecification": {
                    "PredefinedMetricType": "ECSServiceAverageMemoryUtilization"
                },
                "ScaleOutCooldown": 300,
                "ScaleInCooldown": 300
            }
        }
    ]
}
```

**エラーがある場合:**
- 空の配列 `[]` が返される → 設定が登録されていない（コマンドを再実行）
- エラーメッセージが表示される → リソース名やリージョンが間違っている

---

## 5. CloudWatch監視設定

### 5-1. CloudWatchダッシュボードの作成
1. AWSコンソールで「CloudWatch」を検索して開く
2. 左メニュー「ダッシュボード」→「ダッシュボードの作成」
3. **ダッシュボード名**: `blood-pressure-dashboard`
4. 「ダッシュボードの作成」

### 5-2. ウィジェットの追加

#### ECS CPU使用率
1. 「ウィジェットを追加」をクリック
2. **データ型**: 「メトリクス」を選択（デフォルト）
3. **ウィジェットのタイプ**: 「線」を選択
4. 「次へ」をクリック
5. **メトリクスの選択**:
   - サービス一覧から「**ECS**」をクリック
   - 次に表示されるカテゴリから「**ClusterName**」を選択
   - メトリクス一覧から `blood-pressure-cluster` の `CPUUtilization` の**チェックボックスにチェック**
   - ※検索ボックスを使って「blood-pressure-cluster」で絞り込むと見つけやすい
6. 「ウィジェットの作成」をクリック

#### ECS メモリ使用率
1. 「ウィジェットを追加」をクリック
2. **データ型**: 「メトリクス」
3. **ウィジェットのタイプ**: 「線」
4. 「次へ」をクリック
5. **メトリクスの選択**:
   - サービス一覧から「**ECS**」をクリック
   - 「**ClusterName**」を選択
   - `blood-pressure-cluster` の `MemoryUtilization` の**チェックボックスにチェック**
6. 「ウィジェットの作成」をクリック

#### ALB リクエスト数
1. 「ウィジェットを追加」をクリック
2. **データ型**: 「メトリクス」
3. **ウィジェットのタイプ**: 「線」
4. 「次へ」をクリック
5. **メトリクスの選択**:
   - サービス一覧から「**ApplicationELB**」をクリック
   - 「**AppELB 別メトリクス**」を選択（一番下のカテゴリ）
   - メトリクス一覧から `blood-pressure-alb` の `RequestCount` の**チェックボックスにチェック**
   - ※検索ボックスで「blood-pressure-alb」と入力すると見つけやすい
6. 「ウィジェットの作成」をクリック

#### RDS CPU使用率
1. 「ウィジェットを追加」をクリック
2. **データ型**: 「メトリクス」
3. **ウィジェットのタイプ**: 「線」
4. 「次へ」をクリック
5. **メトリクスの選択**:
   - サービス一覧から「**RDS**」をクリック
   - 「**DBInstanceIdentifier**」を選択
   - メトリクス一覧から `blood-pressure-db` の `CPUUtilization` の**チェックボックスにチェック**
   - ※検索ボックスで「blood-pressure-db」と入力すると見つけやすい
6. 「ウィジェットの作成」をクリック

#### ダッシュボードの保存
すべてのウィジェットを追加したら、右上の「**保存**」をクリック

**注意事項:**
- メトリクスが表示されない場合は、リソースがまだ作成されていないか、メトリクスデータがまだ収集されていない可能性があります
- 検索ボックス（「グラフの検索」）を使って、リソース名で絞り込むと見つけやすくなります

### 5-3. アラームの設定

#### ECS高CPU使用率アラーム

**ステップ1: メトリクスと条件の指定**
1. 左メニュー「アラーム状態」→「アラームの作成」
2. 「メトリクスの選択」をクリック
3. ECS → ClusterName → `blood-pressure-cluster` の `CPUUtilization` にチェック → 「メトリクスの選択」をクリック
4. **条件**を設定:
   - **しきい値のタイプ**: 静的
   - **条件**: より大きい
   - **しきい値**: 80
5. 「次へ」をクリック

**ステップ2: アクションの設定**
6. **通知**セクション（オプション）:
   - SNSトピックで通知を受け取る場合は設定
   - 不要な場合は削除して「次へ」をクリック

**ステップ3: アラームの詳細の追加**
7. **アラーム名**: `blood-pressure-high-cpu`
8. **アラームの説明**（オプション）: `ECSクラスターCPU使用率80%超過`
9. 「次へ」をクリック

**ステップ4: プレビューと作成**
10. 設定内容を確認して「アラームの作成」をクリック

#### RDS高CPU使用率アラーム

**ステップ1: メトリクスと条件の指定**
1. 左メニュー「アラーム状態」→「アラームの作成」
2. 「メトリクスの選択」をクリック
3. RDS → DBInstanceIdentifier → `blood-pressure-db` の `CPUUtilization` にチェック → 「メトリクスの選択」
4. **条件**を設定:
   - **しきい値のタイプ**: 静的
   - **条件**: より大きい
   - **しきい値**: 80
5. 「次へ」をクリック

**ステップ2: アクションの設定**
6. 通知が不要な場合は削除して「次へ」をクリック

**ステップ3: アラームの詳細の追加**
7. **アラーム名**: `blood-pressure-db-high-cpu`
8. **アラームの説明**（オプション）: `RDS CPU使用率80%超過`
9. 「次へ」をクリック

**ステップ4: プレビューと作成**
10. 設定内容を確認して「アラームの作成」をクリック

**注意事項:**
- アラーム作成は4ステップのウィザード形式です
- SNS通知が不要な場合は、ステップ2で何も設定せずに「次へ」をクリックしてください

---

## 6. 本番環境の最終調整

### 6-1. Rails設定ファイルの更新

#### config/environments/production.rb
以下の設定を確認・更新:

```ruby
# S3を使用する設定
config.active_storage.service = :amazon

# ホスト設定（ムームードメインで取得したドメインを追加）
config.hosts << "blood-pressure-alb-xxxxxxxxxx.ap-northeast-1.elb.amazonaws.com"
config.hosts << "example.com"        # ルートドメイン
config.hosts << "www.example.com"    # wwwサブドメイン
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

### 6-2. 環境変数の追加

#### 手順

**1. ECSコンソールを開く**
1. AWSコンソールで「ECS」を検索して開く
2. 左メニューから「タスク定義」をクリック

**2. 新しいリビジョンを作成**
3. `blood-pressure-task` を選択
4. 最新のリビジョンのチェックボックスにチェック
5. 「新しいリビジョンの作成」ボタンをクリック
6. 「JSONを使用して設定」をクリック

**3. 環境変数を追加**
7. JSONエディタで `"environment"` セクションを探す
8. 以下の環境変数を追加（既存の環境変数の後に追加）:

```json
{
  "name": "RAILS_SERVE_STATIC_FILES",
  "value": "true"
},
{
  "name": "RAILS_MASTER_KEY",
  "value": "ここにconfig/master.keyの内容を貼り付け"
}
```
# config/master.keyの確認方法や無い場合の対応方法は下記に記載

**4. 作成を完了**
9. 「作成」ボタンをクリック
10. 新しいリビジョンが作成される

**5. ECSサービスを更新**
11. 左メニューから「クラスター」をクリック
12. `blood-pressure-cluster` を選択
13. 「サービス」タブで `blood-pressure-service` を選択
14. 「サービスを更新」ボタンをクリック
15. 「リビジョン」で最新のリビジョンを選択
16. 「強制的に新しいデプロイを実行する」にチェック
17. 「更新」ボタンをクリック

**追加する環境変数:**

| キー | 値 | 説明 |
|------|-----|------|
| RAILS_SERVE_STATIC_FILES | true | Railsが静的ファイルを配信するようにする |
| RAILS_MASTER_KEY | （config/master.keyの内容） | 資格情報の復号化に必要 |

**master.keyの確認方法:**

```bash
# master.keyの内容を表示
cat config/master.key
```

**master.keyが存在しない場合:**

新しく生成する必要があります：

```bash
# 新しいmaster.keyを生成
openssl rand -hex 32 > config/master.key

# 内容を確認
cat config/master.key
```

**重要:** 新しいmaster.keyを生成した場合、既存の `config/credentials.yml.enc` は使用できなくなります。新しくcredentialsを作成する必要があります：

```bash
# credentialsを再作成
RAILS_ENV=production bin/rails credentials:edit
```

**注意事項:**
- `config/master.key` の内容はローカル環境の `config/master.key` ファイルからコピーしてください
- 環境変数は機密情報なので、Gitにコミットしないように注意してください
- サービス更新後、新しいタスクが起動するまで数分かかる場合があります
- master.keyは絶対にGitにコミットしないでください（.gitignoreで除外されていることを確認）

### 6-3. イメージの再ビルドとデプロイ
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

## 7. セキュリティ強化（推奨）

### 7-1. HTTPSの設定（ACM証明書）

#### ACM証明書のリクエスト

**ステップ1: Certificate Managerを開く**
1. AWSコンソールで「**Certificate Manager**」を検索して開く
2. 右上のリージョンが「**東京（ap-northeast-1）**」であることを確認
3. 「**証明書をリクエスト**」ボタンをクリック

**ステップ2: 証明書タイプを選択**
4. 「**パブリック証明書をリクエスト**」を選択（デフォルト）
5. 「**次へ**」ボタンをクリック

**ステップ3: ドメイン名と検証方法を設定**
6. **完全修飾ドメイン名**にドメインを入力:
   - 最初のフィールド: `example.com`（自分のドメインに置き換え）
   - 「**この証明書に別の名前を追加**」をクリック
   - 2番目のフィールド: `*.example.com`（ワイルドカード）
7. **エクスポートを許可**: 「**エクスポートを無効にする**」を選択（デフォルト）
8. **検証方法**: 「**DNS 検証 - 推奨**」を選択
9. **キーアルゴリズム**: 「**RSA 2048**」を選択（デフォルト）
10. **タグ**（オプション）: 必要に応じて追加
11. 「**リクエスト**」ボタンをクリック

#### Route 53でDNS検証（自動）
1. ACMの証明書詳細画面で「Route 53でレコードを作成」ボタンをクリック
2. 「レコードを作成」をクリック
3. 数分で証明書のステータスが「発行済み」になる

**Route 53を使用している場合、DNS検証は自動で完了します。**

#### ALBにHTTPSリスナーを追加

1. **EC2コンソールを開く**
   - AWSコンソールで「EC2」を検索して開く
   - 左メニューから「ロードバランサー」をクリック
   - `blood-pressure-alb` を選択

2. **リスナーを追加**
   - 「**リスナーとルール**」タブをクリック
   - 「**リスナーを追加**」ボタンをクリック

3. **リスナーの設定**
   - **プロトコル**: `HTTPS`（デフォルト）
   - **ポート**: `443`（デフォルト）

4. **デフォルトアクションを設定**
   - **認証アクション**: 設定しない（デフォルト）
   - **アクションのルーティング**: 「**ターゲットグループへ転送**」を選択（デフォルト）
   - **ターゲットグループ**: `blood-pressure-tg` を選択
   - **重み**: `1`（デフォルト）
   - **ターゲットグループの維持**: オフ（デフォルト）

5. **セキュアリスナーの設定**
   - **セキュリティポリシー**: `ELBSecurityPolicy-TLS13-1-2-Res-2021-06 (推奨)`（デフォルト）
   - **証明書の取得先**: 「**ACM から**」を選択（デフォルト）
   - **証明書 (ACM から)**: ドロップダウンからACMで作成した証明書を選択
     - 例: `example.com` または `*.example.com`
   - **クライアント証明書の処理**: 設定しない（デフォルト）

6. **リスナーを追加**
   - 「**リスナーの追加**」ボタンをクリック

**注意事項:**
- 証明書が「発行済み」ステータスになっていることを確認してください
- セキュリティポリシーは推奨されている最新のものを選択してください

#### HTTPからHTTPSへのリダイレクト設定

**ステップ1: HTTP:80リスナーを開く**
1. EC2コンソールで「ロードバランサー」→ `blood-pressure-alb` を選択
2. 「**リスナーとルール**」タブをクリック
3. 「**HTTP:80**」のリスナーをクリック

**ステップ2: デフォルトルールを編集**
4. 「**最後（デフォルト）**」のルールをクリック
5. 右上の「**アクション**」ドロップダウンから「**ルールの編集**」を選択

**ステップ3: リダイレクト設定に変更**
6. 「**デフォルトアクション**」セクションで、「**アクションのルーティング**」
7. 「**URL にリダイレクト**」を選択
8. リダイレクト設定を入力:
   - **プロトコル**: `HTTPS`
   - **ポート**: `443`
   - **ステータスコード**: `301 - 恒久的に移動`
   - その他の項目はデフォルトのまま
9. 「**変更内容の保存**」ボタンをクリック

**確認:**
- HTTP:80のリスナーのデフォルトアクションが「URL にリダイレクト」に変更されていることを確認
- ブラウザで `http://example.com` にアクセスすると自動的に `https://example.com` にリダイレクトされることを確認

### 7-2. WAFの設定（オプション）
1. AWSコンソールで「WAF & Shield」を検索
2. Web ACLを作成してALBに関連付け
3. SQLインジェクション、XSSなどの保護ルールを追加

---

## 8. トラブルシューティング

### ネームサーバーが反映されない場合

#### 確認事項
```bash
# ネームサーバーの確認
nslookup -type=NS example.com

# Route 53のネームサーバーが表示されるか確認
# 例: ns-123.awsdns-12.com
```

#### 対処法
1. ムームードメインのコントロールパネルでネームサーバー設定を再確認
2. Route 53のネームサーバーが正しく入力されているか確認
3. 設定変更後、最大48時間待つ
4. キャッシュをクリアして再確認: `nslookup -type=NS example.com 8.8.8.8`

### ドメインにアクセスできない場合

#### 確認事項
1. ネームサーバーがRoute 53に変更されているか確認
2. Route 53でAレコード（エイリアス）が作成されているか確認
3. ALBが正常に動作しているか確認
4. セキュリティグループでポート80/443が開いているか確認

#### 対処法
```bash
# ALBに直接アクセスして動作確認
curl http://blood-pressure-alb-123456789.ap-northeast-1.elb.amazonaws.com

# ドメインの名前解決を確認
dig example.com
```

---

## 完了！

これでムームードメインを使用したAWSへのデプロイが完了しました。

### 確認事項チェックリスト
- [ ] ドメインでアプリケーションにアクセスできる（http://example.com）
- [ ] HTTPSでアクセスできる（https://example.com）
- [ ] HTTPからHTTPSへ自動リダイレクトされる
- [ ] ログインできる
- [ ] 血圧記録の登録・閲覧ができる
- [ ] グラフが表示される
- [ ] Auto Scalingが動作する
- [ ] CloudWatchでメトリクスが確認できる

### アクセスURL
- **HTTP**: http://example.com（自動的にHTTPSにリダイレクト）
- **HTTPS**: https://example.com
- **www付き**: https://www.example.com

### トラブルシューティング
問題が発生した場合は「AWS_DEPLOY_07_トラブルシューティング.md」を参照してください。
