# AWS RDS PostgreSQL データベース操作手順

## 目次
1. RDSへの接続方法
2. データベースの確認
3. データの閲覧
4. データの編集
5. バックアップとリストア

---

## 1. RDSへの接続方法

### 1-1. EC2踏み台サーバー経由での接続（推奨）

RDSはプライベートサブネットにあるため、EC2インスタンスを経由して接続します。

#### 踏み台EC2の起動
1. AWSコンソールで「EC2」を検索
2. 「インスタンスを起動」
3. 以下の設定:
   - **名前**: `blood-pressure-bastion`
   - **AMI**: Amazon Linux 2023
   - **インスタンスタイプ**: t2.micro
   - **キーペア**: 上記で作成した `blood-pressure-bastion-key` を選択
      #### キーペアの作成（初回のみ）

      新規作成する場合は以下の設定を推奨:

      1. **キーペア名**: `blood-pressure-bastion-key`（任意の名前）
      2. **キーペアのタイプ**: **RSA**（推奨）
      3. **プライベートキーファイル形式**:
        - Mac/Linux: **.pem**
        - Windows（PuTTY使用）: **.ppk**
        - Windows（標準SSH使用）: **.pem**
      4. 「キーペアを作成」をクリック
      5. プライベートキーファイルが自動ダウンロードされる

      #### キーファイルの保存と権限設定

      ```bash
      # ダウンロードしたキーを安全な場所に移動
      mkdir -p ~/.ssh
      mv ~/Downloads/blood-pressure-bastion-key.pem ~/.ssh/

      # 権限を読み取り専用に変更（重要）
      chmod 400 ~/.ssh/blood-pressure-bastion-key.pem
      ```

      ⚠️ **重要**: プライベートキーは再ダウンロード不可。紛失した場合は新規作成が必要。

   - **ネットワーク設定**:
     - VPC: `blood-pressure-vpc`
     - サブネット: `blood-pressure-public-subnet-1a`
     - パブリックIP: 有効化
     - セキュリティグループ: 新規作成
       
       #### セキュリティグループの設定
       - **セキュリティグループ名**: `blood-pressure-bastion-sg`
       - **説明**: `Security group for bastion server to access RDS`
       - **インバウンドルール**:
         - タイプ: SSH
         - プロトコル: TCP
         - ポート範囲: 22
         - ソースタイプ: 自分のIP（自動的に自分のIPアドレスが設定される）
         - 説明: `SSH access from my IP`
       
       ⚠️ **セキュリティ**: ソースタイプは必ず「自分のIP」を選択し、0.0.0.0/0（全世界）は避けること
       
4. 「インスタンスを起動」

#### PostgreSQLクライアントのインストール
```bash
# EC2にSSH接続
ssh -i ~/.ssh/blood-pressure-bastion-key.pem ec2-user@<EC2のパブリックIP>

ssh -i ~/.ssh/blood-pressure-bastion-key.pem ec2-user@3.112.204.0


# PostgreSQLクライアントをインストール
sudo dnf install -y postgresql15

```

#### RDSへの接続
```bash
# RDSエンドポイントを確認（AWSコンソールのRDS画面から取得）
# 例: blood-pressure-db.xxxxxxxxxx.ap-northeast-1.rds.amazonaws.com

# PostgreSQLに接続
psql -h blood-pressure-db.xxxxxxxxxx.ap-northeast-1.rds.amazonaws.com \
     -U postgres \
     -d blood_pressure_production

psql -h blood-pressure-db.cn2io2gceq5f.ap-northeast-1.rds.amazonaws.com \
     -U postgres \
     -d blood_pressure_production

# パスワードを入力（RDS作成時に設定したもの）
```

### 1-2. ECSタスクから接続

```bash
# ECSタスクIDを取得
aws ecs list-tasks \
  --cluster blood-pressure-cluster \
  --service-name blood-pressure-service \
  --region ap-northeast-1

# タスクに接続
aws ecs execute-command \
  --cluster blood-pressure-cluster \
  --task <タスクID> \
  --container web \
  --interactive \
  --command "/bin/bash" \
  --region ap-northeast-1

# コンテナ内でRailsコンソールを起動
bundle exec rails console -e production

# またはpsqlで直接接続
psql $DATABASE_URL
```

---

## 2. データベースの確認

### 2-1. データベース一覧
```sql
-- データベース一覧を表示
\l

-- 現在のデータベースに接続
\c blood_pressure_production
```

### 2-2. テーブル一覧
```sql
-- テーブル一覧を表示
\dt

-- テーブル構造を確認
\d users
\d blood_pressure_records
\d hospitals
\d roles
\d user_hospital_roles
\d patient_staff_assignments
```

### 2-3. レコード数の確認
```sql
-- 各テーブルのレコード数を確認
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM blood_pressure_records;
SELECT COUNT(*) FROM hospitals;
SELECT COUNT(*) FROM roles;
SELECT COUNT(*) FROM user_hospital_roles;
SELECT COUNT(*) FROM patient_staff_assignments;
```

---

## 3. データの閲覧

### 3-1. ユーザー情報の確認
```sql
-- 全ユーザーを表示
SELECT id, email, name, created_at FROM users ORDER BY id;

-- 特定のユーザーを検索
SELECT * FROM users WHERE email = 'admin@system.com';

-- ユーザーの役割を確認
SELECT 
  u.id, u.email, u.name,
  r.name as role_name,
  h.name as hospital_name,
  uhr.permission_level
FROM users u
JOIN user_hospital_roles uhr ON u.id = uhr.user_id
JOIN roles r ON uhr.role_id = r.id
JOIN hospitals h ON uhr.hospital_id = h.id
ORDER BY u.id;
```

### 3-2. 血圧記録の確認
```sql
-- 最新の血圧記録を表示
SELECT 
  bpr.id,
  u.name as patient_name,
  bpr.systolic,
  bpr.diastolic,
  bpr.pulse,
  bpr.measured_at,
  bpr.created_at
FROM blood_pressure_records bpr
JOIN users u ON bpr.user_id = u.id
ORDER BY bpr.measured_at DESC
LIMIT 20;

-- 特定の患者の血圧記録
SELECT * FROM blood_pressure_records 
WHERE user_id = 1 
ORDER BY measured_at DESC;

-- 日付範囲で検索
SELECT * FROM blood_pressure_records 
WHERE measured_at BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY measured_at DESC;
```

### 3-3. 病院情報の確認
```sql
-- 病院一覧
SELECT * FROM hospitals ORDER BY id;

-- 病院に所属するスタッフ数
SELECT 
  h.name as hospital_name,
  COUNT(DISTINCT uhr.user_id) as staff_count
FROM hospitals h
LEFT JOIN user_hospital_roles uhr ON h.id = uhr.hospital_id
GROUP BY h.id, h.name;
```

### 3-4. 患者とスタッフの割り当て確認
```sql
-- 患者とスタッフの関係
SELECT 
  p.name as patient_name,
  s.name as staff_name,
  psa.created_at as assigned_at
FROM patient_staff_assignments psa
JOIN users p ON psa.patient_id = p.id
JOIN users s ON psa.staff_id = s.id
ORDER BY psa.created_at DESC;
```

---

## 4. データの編集

### 4-1. ユーザー情報の更新
```sql
-- メールアドレスの変更
UPDATE users 
SET email = 'newemail@example.com' 
WHERE id = 1;

-- ユーザー名の変更
UPDATE users 
SET name = '新しい名前' 
WHERE id = 1;

-- パスワードのリセット（Railsコンソール推奨）
-- psqlではなくRailsコンソールで実行:
-- user = User.find(1)
-- user.password = 'newpassword123'
-- user.save
```

### 4-2. 血圧記録の編集
```sql
-- 血圧値の修正
UPDATE blood_pressure_records 
SET systolic = 120, diastolic = 80, pulse = 70
WHERE id = 1;

-- 測定日時の修正
UPDATE blood_pressure_records 
SET measured_at = '2024-01-15 10:30:00'
WHERE id = 1;

-- メモの追加
UPDATE blood_pressure_records 
SET memo = '朝食後に測定'
WHERE id = 1;
```

### 4-3. データの削除
```sql
-- 特定の血圧記録を削除
DELETE FROM blood_pressure_records WHERE id = 1;

-- 特定期間の血圧記録を削除
DELETE FROM blood_pressure_records 
WHERE measured_at < '2023-01-01';

-- ユーザーの削除（関連データも削除される場合があるので注意）
DELETE FROM users WHERE id = 1;
```

### 4-4. 役割の割り当て
```sql
-- ユーザーに役割を追加
INSERT INTO user_hospital_roles (user_id, hospital_id, role_id, permission_level, created_at, updated_at)
VALUES (1, 1, 2, 0, NOW(), NOW());
-- permission_level: 0=general, 1=administrator

-- 役割の削除
DELETE FROM user_hospital_roles 
WHERE user_id = 1 AND hospital_id = 1 AND role_id = 2;
```

---

## 5. バックアップとリストア

### 5-1. データベースのバックアップ

#### 手動バックアップ（EC2から実行）
```bash
# 全データベースをバックアップ
pg_dump -h blood-pressure-db.xxxxxxxxxx.ap-northeast-1.rds.amazonaws.com \
        -U postgres \
        -d blood_pressure_production \
        -F c \
        -f backup_$(date +%Y%m%d_%H%M%S).dump

# SQLファイルとしてバックアップ
pg_dump -h blood-pressure-db.xxxxxxxxxx.ap-northeast-1.rds.amazonaws.com \
        -U postgres \
        -d blood_pressure_production \
        -f backup_$(date +%Y%m%d_%H%M%S).sql
```

#### 特定のテーブルのみバックアップ
```bash
pg_dump -h blood-pressure-db.xxxxxxxxxx.ap-northeast-1.rds.amazonaws.com \
        -U postgres \
        -d blood_pressure_production \
        -t blood_pressure_records \
        -f blood_pressure_records_backup.sql
```

#### S3へのアップロード
```bash
# AWS CLIでS3にアップロード
aws s3 cp backup_20240115_120000.dump s3://blood-pressure-backups/
```

### 5-2. RDS自動バックアップの設定

1. AWSコンソールで「RDS」を開く
2. `blood-pressure-db` を選択
3. 「変更」をクリック
4. **バックアップ**セクション:
   - **自動バックアップ**: 有効
   - **バックアップ保持期間**: 7日間（推奨）
   - **バックアップウィンドウ**: 優先バックアップウィンドウを選択（例: 03:00-04:00 JST）
5. 「続行」→「すぐに適用」

### 5-3. スナップショットの作成

1. RDSコンソールで `blood-pressure-db` を選択
2. 「アクション」→「スナップショットの取得」
3. **スナップショット名**: `blood-pressure-db-snapshot-20240115`
4. 「スナップショットの取得」

### 5-4. データのリストア

#### バックアップファイルからリストア
```bash
# カスタム形式のバックアップからリストア
pg_restore -h blood-pressure-db.xxxxxxxxxx.ap-northeast-1.rds.amazonaws.com \
           -U postgres \
           -d blood_pressure_production \
           -c \
           backup_20240115_120000.dump

# SQLファイルからリストア
psql -h blood-pressure-db.xxxxxxxxxx.ap-northeast-1.rds.amazonaws.com \
     -U postgres \
     -d blood_pressure_production \
     -f backup_20240115_120000.sql
```

#### RDSスナップショットからリストア
1. RDSコンソールで「スナップショット」を選択
2. リストアしたいスナップショットを選択
3. 「アクション」→「スナップショットの復元」
4. 新しいDBインスタンス識別子を入力
5. 「DBインスタンスの復元」

---

## 6. 便利なSQLクエリ集

### 6-1. 統計情報
```sql
-- 患者ごとの血圧記録数
SELECT 
  u.name,
  COUNT(bpr.id) as record_count,
  MIN(bpr.measured_at) as first_record,
  MAX(bpr.measured_at) as last_record
FROM users u
LEFT JOIN blood_pressure_records bpr ON u.id = bpr.user_id
GROUP BY u.id, u.name
ORDER BY record_count DESC;

-- 月別の血圧記録数
SELECT 
  DATE_TRUNC('month', measured_at) as month,
  COUNT(*) as record_count
FROM blood_pressure_records
GROUP BY month
ORDER BY month DESC;

-- 平均血圧値
SELECT 
  u.name,
  ROUND(AVG(bpr.systolic), 1) as avg_systolic,
  ROUND(AVG(bpr.diastolic), 1) as avg_diastolic,
  ROUND(AVG(bpr.pulse), 1) as avg_pulse
FROM users u
JOIN blood_pressure_records bpr ON u.id = bpr.user_id
GROUP BY u.id, u.name;
```

### 6-2. データクリーニング
```sql
-- 重複レコードの確認
SELECT user_id, measured_at, COUNT(*)
FROM blood_pressure_records
GROUP BY user_id, measured_at
HAVING COUNT(*) > 1;

-- 異常値の確認
SELECT * FROM blood_pressure_records
WHERE systolic > 250 OR systolic < 50
   OR diastolic > 150 OR diastolic < 30
   OR pulse > 200 OR pulse < 30;
```

---

## 7. セキュリティとベストプラクティス

### 注意事項
- **本番データベースへの直接接続は最小限に**
- **変更前は必ずバックアップを取得**
- **DELETE/UPDATE文は必ずWHERE句を確認**
- **トランザクションを使用して安全に操作**

### トランザクションの使用
```sql
-- トランザクション開始
BEGIN;

-- 変更を実行
UPDATE users SET email = 'newemail@example.com' WHERE id = 1;

-- 確認
SELECT * FROM users WHERE id = 1;

-- 問題なければコミット、問題があればロールバック
COMMIT;
-- または
ROLLBACK;
```

### 読み取り専用ユーザーの作成
```sql
-- 読み取り専用ユーザーを作成
CREATE USER readonly_user WITH PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE blood_pressure_production TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
```

---

## トラブルシューティング

### 接続できない場合
1. セキュリティグループの確認（RDSとEC2の両方）
2. RDSエンドポイントの確認
3. データベース名、ユーザー名、パスワードの確認
4. VPCとサブネットの設定確認

### パフォーマンスが遅い場合
```sql
-- 実行中のクエリを確認
SELECT pid, usename, state, query, query_start
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- インデックスの確認
\di

-- テーブルサイズの確認
SELECT 
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

## 参考リンク
- [PostgreSQL公式ドキュメント](https://www.postgresql.org/docs/)
- [AWS RDS PostgreSQLドキュメント](https://docs.aws.amazon.com/ja_jp/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [Rails Active Recordガイド](https://railsguides.jp/active_record_basics.html)
