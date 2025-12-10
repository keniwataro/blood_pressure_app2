# AWSデプロイ手順 Part 5: ECS（Fargate）構築

## 目次
1. ECSクラスター作成
2. タスク定義作成
3. ALB作成
4. ECSサービス作成

---

## 1. ECSクラスター作成

### 1-0. 事前準備：ECSサービスリンクロールの作成
ECSを初めて使用する場合、サービスリンクロールを作成する必要があります。

```bash
aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com
```

**※「すでに存在する」というエラーが出た場合は、ロールは既に作成されているので問題ありません。**

### 1-1. クラスターの作成
1. AWSコンソールで「ECS」または「Elastic Container Service」を検索して開く
2. 左メニューから「クラスター」を選択
3. 「クラスターの作成」ボタンをクリック
4. 以下を設定:
   
   **クラスター設定**
   - **クラスター名**: `blood-pressure-cluster`
   
   **インフラストラクチャ**
   - **Fargate のみ** を選択（デフォルト）
   
   **モニタリング**（オプション）
   - Container Insights: 有効化（推奨、追加料金が発生）または無効
   
   **タグ**（オプション）
   - 必要に応じてタグを追加

5. 「作成」ボタンをクリック
6. クラスターが作成されるまで数秒待つ

---

## 2. タスク定義作成

### 2-1. タスク実行ロールの作成
1. AWSコンソールで「IAM」を検索して開く
2. 左メニュー「ロール」→「ロールを作成」
3. **信頼されたエンティティタイプ**: AWSのサービス
4. **ユースケース**: Elastic Container Service → Elastic Container Service Task
5. 「次へ」をクリック
6. 以下のポリシーを検索して選択:
   - `AmazonECSTaskExecutionRolePolicy`
   - `AmazonS3FullAccess`（S3アクセス用）
7. 「次へ」をクリック
8. **ロール名**: `ecsTaskExecutionRole`
9. 「ロールを作成」

### 2-2. タスクロールの作成（ECS Exec用）
1. IAMコンソールで「ロール」→「ロールを作成」
2. **信頼されたエンティティタイプ**: AWSのサービス
3. **ユースケース**: Elastic Container Service → Elastic Container Service Task
4. 「次へ」をクリック
5. 以下のポリシーを検索して選択:
   - `AmazonSSMManagedInstanceCore`（ECS Exec用）
   - `AmazonS3FullAccess`（S3アクセス用）
6. 「次へ」をクリック
7. **ロール名**: `ecsTaskRole`
8. 「ロールを作成」

### 2-3. タスク定義の作成
1. ECSコンソールに戻る
2. 左メニュー「タスク定義」→「新しいタスク定義の作成」
3. **タスク定義ファミリー**: `blood-pressure-task`
4. **起動タイプ**: AWS Fargate
5. **オペレーティングシステム/アーキテクチャ**: Linux/X86_64
6. **タスクサイズ**:
   - **CPU**: 0.5 vCPU
   - **メモリ**: 1 GB
7. **タスクロール**: `ecsTaskRole`
8. **タスク実行ロール**: `ecsTaskExecutionRole`

### 2-4. コンテナの追加
1. 「コンテナ - 1」セクションで以下を入力:
   - **名前**: `rails-app`
   - **イメージURI**: `123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/blood-pressure-app:latest`
     - ※自分のECRリポジトリURIに置き換える
   - **ポートマッピング**:
     - **コンテナポート**: 3000
     - **プロトコル**: TCP
     - **ポート名**: `rails-3000`
     - **アプリケーションプロトコル**: HTTP
   - **リソース割り当て制限**: デフォルトのまま（空欄）
     - ※タスクレベルで設定済みのため、コンテナレベルの設定は不要

### 2-5. 環境変数の設定
「環境変数」セクションで以下を追加:

| キー | 値 |
|------|-----|
| RAILS_ENV | production |
| RAILS_LOG_TO_STDOUT | true |
| DATABASE_HOST | blood-pressure-db.xxxxxxxxxx.ap-northeast-1.rds.amazonaws.com |
| DATABASE_PORT | 5432 |
| DATABASE_NAME | blood_pressure_production |
| DATABASE_USERNAME | postgres |
| DATABASE_PASSWORD | （RDSで設定したパスワード） |
| SECRET_KEY_BASE | （後述のコマンドで生成） |
| AWS_REGION | ap-northeast-1 |
| AWS_S3_BUCKET | blood-pressure-app-assets-20251018 |

＊blood-pressure-db.xxxxxxxxxx.ap-northeast-1.rds.amazonaws.comは作成したDBのエンドポイント

**SECRET_KEY_BASEの生成方法:**

方法: Docker Composeを起動してから下記のコマンドを実行
```bash
docker-compose up -d

docker-compose exec web rails secret
```

出力された128文字の文字列をコピーして使用

### 2-6. ログ設定
1. 「ログ収集」セクションで「ログ収集の使用」を有効化（チェックを入れる）
2. デフォルト設定が自動で設定されます:
   - **awslogs-group**: `/ecs/blood-pressure-task`
   - **awslogs-region**: `ap-northeast-1`
   - **awslogs-stream-prefix**: `ecs`
   - **awslogs-create-group**: `true`
3. そのままデフォルト設定で問題ありません
4. 下にスクロールして「作成」ボタンをクリック

---

## 3. ALB作成

### 3-1. ターゲットグループの作成
1. AWSコンソールで「EC2」を検索して開く
2. 左メニュー「ターゲットグループ」→「ターゲットグループの作成」
3. **基本設定**:
   - **ターゲットタイプ**: IPアドレス
   - **ターゲットグループ名**: `blood-pressure-tg`
   - **プロトコル**: HTTP
   - **ポート**: 3000
   - **VPC**: `blood-pressure-vpc`
   - **プロトコルバージョン**: HTTP1

4. **ヘルスチェック**:
   - **ヘルスチェックプロトコル**: HTTP
   - **ヘルスチェックパス**: `/users/sign_in`
   
   **ヘルスチェックの詳細設定**（展開する）:
   - **ヘルスチェックポート**: トラフィックポート（デフォルト）
   - **正常のしきい値**: 2
   - **非正常のしきい値**: 2（デフォルト）
   - **タイムアウト**: 5秒（デフォルト）
   - **間隔**: 30秒
   - **成功コード**: 200,301,302

5. 「次へ」をクリック
6. ターゲットの登録はスキップ（ECSが自動登録）
7. 「ターゲットグループの作成」をクリック

### 3-2. ALBの作成
1. 左メニュー「ロードバランサー」→「ロードバランサーの作成」
2. 「Application Load Balancer」の「作成」をクリック

3. **基本的な設定**:
   - **ロードバランサー名**: `blood-pressure-alb`
   - **スキーム**: インターネット向け
   - **IPアドレスタイプ**: IPv4

4. **ネットワークマッピング**:
   - **VPC**: `blood-pressure-vpc` を選択
   - **IPプール**: デフォルト（チェックなし）
   - **アベイラビリティーゾーンとサブネット**:
     - 少なくとも2つのアベイラビリティーゾーンを選択
     - 例: `ap-northeast-1a` と `ap-northeast-1c`
     - 各ゾーンで**パブリックサブネット**を選択
     - ※VPC作成時に作成したパブリックサブネット2つを選択

5. **セキュリティグループ**:
   - `blood-pressure-alb-sg` を選択
   - ※デフォルトのセキュリティグループは削除して、ALB用のセキュリティグループのみを選択

6. **リスナーとルーティング**:
   - **プロトコル**: HTTP
   - **ポート**: 80
   - **デフォルトアクション**: `blood-pressure-tg` を選択

7. 「ロードバランサーの作成」をクリック

### 3-3. ALB DNSの確認
1. 作成したALBをクリック
2. **DNS名**をメモ:
   ```
   blood-pressure-alb-xxxxxxxxxx.ap-northeast-1.elb.amazonaws.com
   ```

---

## 4. ECSサービス作成

### 4-1. サービスの作成
1. ECSコンソールに戻る
2. `blood-pressure-cluster` をクリック
3. 「サービス」タブ→「作成」ボタンをクリック

4. **サービスの詳細**:
   - **タスク定義ファミリー**: `blood-pressure-task` を選択
   - **タスク定義のリビジョン**: 空欄（最新リビジョンを使用）
   - **サービス名**: `blood-pressure-service`

5. **環境**:
   - **既存のクラスター**: `blood-pressure-cluster`（自動設定済み）
   
   **コンピューティング設定**（展開する）:
   - **コンピューティングオプション**: 起動タイプ
   - **起動タイプ**: FARGATE（デフォルト）
   - **プラットフォームバージョン**: LATEST（デフォルト）

6. **デプロイ設定**:
   - **スケジューリング戦略**: レプリカ（デフォルト）
   - **必要なタスク**: 1（または2）
   - **アベイラビリティーゾーンの再調整**: 有効化（推奨）
   - **ヘルスチェックの猶予期間**: 0秒（デフォルト）
   - その他の設定はデフォルトのまま

7. **ネットワーキング**（展開する）:
   - **VPC**: `blood-pressure-vpc` を選択
   - **サブネット**: プライベートサブネット2つを選択
     - ※VPC作成時に作成したプライベートサブネットを選択
   - **セキュリティグループ**: 
     - 「既存のセキュリティグループを使用」を選択
     - `blood-pressure-ecs-sg` を選択
     - ※デフォルトのセキュリティグループは削除
   - **パブリックIP**: オフ（無効）
     - ※ALB経由でアクセスするため、タスクにパブリックIPは不要
   
   **ロードバランシング**（展開する）:
   - **ロードバランシングを使用**: チェックを入れる
   - **VPC**: `vpc-xxxxxxxxxxxxxx`(blood-pressure-vpcの値)（自動設定済み）
   - **ロードバランサーの種類**: Application Load Balancer を選択
   - **コンテナ**: `rails-app 3000:3000` を選択
   
   **Application Load Balancer**:
   - **既存のロードバランサーを使用** を選択
   - **ロードバランサー名**: `blood-pressure-alb` を選択
   
   **リスナー**:
   - **既存のリスナーを使用** を選択
   - **リスナー**: HTTP:80
   
   **ターゲットグループ**:
   - **既存のターゲットグループを使用** を選択
   - **ターゲットグループ名**: `blood-pressure-tg` を選択
   - **ヘルスチェックパス**: `/users/sign_in`
   - **ヘルスチェックプロトコル**: HTTP
   
   ※他のネットワーキング設定（Service Connect、サービス検出、VPC Latticeなど）はデフォルトのまま（無効）

8. 下にスクロールして「作成」ボタンをクリック

### 4-2. サービスの起動確認
1. サービスが作成されるまで待つ（2〜3分）
2. 「タスク」タブでタスクのステータスが「実行中」になることを確認

---

## 5. データベースのマイグレーション

### 5-0. 事前準備：Session Manager Pluginのインストール
ECS Execを使用するには、Session Manager Pluginが必要です。

**Linuxの場合（wslの場合も）:**
```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
session-manager-plugin  # インストール確認
```

**macOSの場合:**
```bash
brew install --cask session-manager-plugin
session-manager-plugin  # インストール確認
```

**Windowsの場合:**
[Session Manager Plugin for Windows](https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe) をダウンロードしてインストール

### 5-1. ECS Execの有効化
サービスを更新してECS Execを有効化します。

```bash
aws ecs update-service \
  --cluster blood-pressure-cluster \
  --service blood-pressure-service \
  --task-definition blood-pressure-task \
  --enable-execute-command \
  --force-new-deployment \
  --region ap-northeast-1
```

**重要**: 新しいタスクが起動するまで2～3分待ちます。ECSコンソールで「タスク」タブを確認し、新しいタスクが「実行中」になることを確認してください。

### 5-2. 新しいタスクIDの取得
```bash
aws ecs list-tasks \
  --cluster blood-pressure-cluster \
  --service-name blood-pressure-service \
  --region ap-northeast-1
```

新しいタスクARNをコピー（例: `arn:aws:ecs:ap-northeast-1:111122221111:task/blood-pressure-cluster/abc123...`）

**注意**: 古いタスクIDではなく、手顥5-1で起動した新しいタスクIDを使用してください。

### 5-3. マイグレーション実行
タスクARN全体を使用してコンテナに接続します。

```bash
aws ecs execute-command \
  --cluster blood-pressure-cluster \
  --task arn:aws:ecs:ap-northeast-1:111122221111:task/blood-pressure-cluster/abc123... \
  --container rails-app \
  --interactive \
  --command "/bin/bash" \
  --region ap-northeast-1

```

**※タスクARNを実際の値に置き換えてください。**

接続に成功したら、コンテナ内で以下を実行:
```bash
bundle exec rails db:migrate
bundle exec rails db:seed

# システム管理者ユーザー用変数
system_admin_role = Role.find_or_create_by!(id: 1, name: 'システム管理者') do |role|
  role.is_medical_staff = false
  role.is_hospital_role = false
  role.description = 'システム全体を管理する管理者'
end

# システム管理用の病院id用変数
system_hospital = Hospital.find_or_create_by!(id: 1, name: 'システム管理') do |hospital|
  hospital.address = 'システム管理用'
end

# システム管理者ユーザーの作成
admin_user = User.find_or_create_by!(email: 'admin@system.com') do |user|
  user.name = 'システム管理者'
  user.password = 'admin123'
  user.password_confirmation = 'admin123'
end

# システム管理者ユーザーに病院役割を割り当て
admin_uhr = UserHospitalRole.find_or_create_by!(user: admin_user, hospital: system_hospital, role: system_admin_role)

# 現在の役割の設定
admin_user.update!(current_hospital_role_id: admin_uhr.id)

# ユーザーの確認
User.find_by(email: 'admin@system.com').user_id

exit
```

---

## 6. 動作確認

### 6-1. アプリケーションへのアクセス
ブラウザで以下にアクセス:
```
http://blood-pressure-alb-xxxxxxxxxx.ap-northeast-1.elb.amazonaws.com

```

ログイン画面が表示されれば成功です！

---

## 次のステップ

ECS構築が完了したら、次のファイル「AWS_DEPLOY_06_Route53_AutoScaling.md」に進んでください。
