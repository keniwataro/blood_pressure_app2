# AWSリソース削除手順

## 概要

このガイドは、AWSにデプロイした血圧管理アプリケーションの全リソースを削除するための手順書です。
**削除は逆順で行います**（作成の逆順）。

---

## ⚠️ 重要な注意事項

- **削除したリソースは復元できません**
- **データベースのバックアップを取得してから削除してください**
- **削除前に本当に削除して良いか確認してください**
- **削除には時間がかかる場合があります（最大30分程度）**
- **一部のリソースは削除に失敗する場合があります。その場合は依存関係を確認してください**

---

## 削除の順序

1. Route53設定削除（設定している場合）
2. CloudWatch設定削除
3. ECSサービス・タスク削除
4. ALB・ターゲットグループ削除
5. ECRイメージ・リポジトリ削除
6. RDSインスタンス削除
7. S3バケット削除
8. VPC関連リソース削除
9. IAMロール削除
10. CloudWatchロググループ削除

---

## 1. Route53設定削除（設定している場合）

### 1-1. レコードの削除
1. AWSコンソールで「Route 53」を検索して開く
2. 左メニュー「ホストゾーン」
3. 該当のホストゾーンをクリック
4. ALBへのAレコードを選択
5. 「レコードを削除」をクリック
消せるレコードは全て削除

### 1-2. ホストゾーンの削除
1. ホストゾーン一覧に戻る
2. 該当のホストゾーンを選択
3. 「削除」をクリック
4. 確認メッセージで「削除」を入力して確認

---

## 2. CloudWatch設定削除

### 2-1. アラームの削除
1. AWSコンソールで「CloudWatch」を検索して開く
2. 左メニュー「アラーム」→「すべてのアラーム」
3. 以下のアラームを選択:
   - `blood-pressure-high-cpu`
   - `blood-pressure-db-high-cpu`
4. 「アクション」→「削除」

### 2-2. ダッシュボードの削除
1. 左メニュー「ダッシュボード」
2. `blood-pressure-dashboard` を選択
3. 「削除」をクリック

---

## 3. ECSサービス・タスク削除

### 3-1. ECSサービスの削除
1. AWSコンソールで「ECS」を検索して開く
2. `blood-pressure-cluster` をクリック
3. 「サービス」タブ
4. `blood-pressure-service` を選択
5. 「削除」をクリック
6. 確認メッセージで `削除` を入力
7. 「削除」をクリック

**削除には5〜10分かかります。完全に削除されるまで待ちます。**

### 3-2. タスク定義の登録解除
1. 左メニュー「タスク定義」
2. `blood-pressure-task` をクリック
3. 全てのリビジョンを選択
4. 「アクション」→「登録解除」

### 3-3. ECSクラスターの削除
1. 左メニュー「クラスター」
2. `blood-pressure-cluster` を選択
3. 「クラスターの削除」をクリック
4. 確認メッセージで `delete blood-pressure-cluster` を入力
5. 「削除」をクリック

---

## 4. ALB・ターゲットグループ削除

### 4-1. ALBの削除
1. AWSコンソールで「EC2」を検索して開く
2. 左メニュー「ロードバランサー」
3. `blood-pressure-alb` を選択
4. 「アクション」→「ロードバランサーの削除」
5. 確認メッセージで `確認` を入力
6. 「削除」をクリック

**削除には数分かかります。**

### 4-2. ターゲットグループの削除
1. 左メニュー「ターゲットグループ」
2. `blood-pressure-tg` を選択
3. 「アクション」→「削除」
4. 「はい、削除します」をクリック

---

## 5. ECRイメージ・リポジトリ削除

### 5-1. ECRイメージの削除
1. AWSコンソールで「Elastic Container Registry」を検索して開く
2. `blood-pressure-app` リポジトリをクリック
3. 全てのイメージを選択
4. 「削除」をクリック
5. 確認メッセージで `delete` を入力
6. 「削除」をクリック

### 5-2. ECRリポジトリの削除
1. リポジトリ一覧に戻る
2. `blood-pressure-app` を選択
3. 「削除」をクリック
4. 確認メッセージで `delete` を入力
5. 「削除」をクリック

---

## 6. RDSインスタンス削除

### 6-1. RDSインスタンスの削除
1. AWSコンソールで「RDS」を検索して開く
2. 左メニュー「データベース」
3. `blood-pressure-db` を選択
4. 「アクション」→「削除」
5. 削除オプション:
   - **最終スナップショットを作成**: チェックを外す（データが不要な場合）
     - ※データを保存したい場合はチェックを入れてスナップショット名を指定
   - **自動バックアップを保持**: チェックを外す
   - 確認メッセージで `delete me` を入力
6. 「削除」をクリック

**削除には10〜15分かかります。完全に削除されるまで待ちます。**

### 6-2. DBサブネットグループの削除
1. 左メニュー「サブネットグループ」
2. `blood-pressure-db-subnet-group` を選択
3. 「削除」をクリック
4. 「削除」を確認

---

## 7. S3バケット削除

### 7-1. S3バケットの空にする
1. AWSコンソールで「S3」を検索して開く
2. `blood-pressure-app-assets-xxxxxxxx` バケットを選択
3. 「空にする」をクリック
4. 確認メッセージで `完全に削除` を入力
5. 「空にする」をクリック

### 7-2. S3バケットの削除
1. バケット一覧に戻る
2. `blood-pressure-app-assets-xxxxxxxx` を選択
3. 「削除」をクリック
4. 確認メッセージでバケット名を入力
5. 「バケットを削除」をクリック

---

## 8. VPC関連リソース削除

### 8-1. NATゲートウェイの削除
1. AWSコンソールで「VPC」を検索して開く
2. 左メニュー「NATゲートウェイ」
3. `blood-pressure` に関連するNATゲートウェイを選択
4. 「アクション」→「NATゲートウェイの削除」
5. 確認メッセージで `削除` を入力
6. 「削除」をクリック

**削除には数分かかります。ステータスが「削除済み」になるまで待ちます。**

### 8-2. Elastic IPの解放
1. 左メニュー「Elastic IP」
2. NATゲートウェイに関連付けられていたElastic IPを選択
3. 「アクション」→「Elastic IPアドレスの解放」
4. 「解放」をクリック

### 8-3. セキュリティグループの削除
1. 左メニュー「セキュリティグループ」
2. 以下のセキュリティグループを順番に削除:
   - `blood-pressure-ecs-sg`（先に削除）
   - `blood-pressure-rds-sg`
   - `blood-pressure-alb-sg`
3. 各セキュリティグループを選択
4. 「アクション」→「セキュリティグループの削除」
5. 「削除」をクリック

**注意**: 依存関係があるため、ECS→RDS→ALBの順で削除してください。

### 8-4. VPCの削除
1. 左メニュー「VPC」
2. `blood-pressure-vpc` を選択
3. 「アクション」→「VPCを削除」
4. 確認メッセージで `削除` を入力
5. 「削除」をクリック

**VPCを削除すると、関連する以下のリソースも自動的に削除されます:**
- サブネット（パブリック・プライベート）
- ルートテーブル
- インターネットゲートウェイ
- ネットワークACL

---

## 9. IAMロール削除

### 9-1. ECSタスク実行ロールの削除
1. AWSコンソールで「IAM」を検索して開く
2. 左メニュー「ロール」
3. `ecsTaskExecutionRole` を検索して選択
4. 「削除」をクリック
5. 確認メッセージでロール名を入力
6. 「削除」をクリック

### 9-2. ECSタスクロールの削除
1. `ecsTaskRole` を検索して選択
2. 「削除」をクリック
3. 確認メッセージでロール名を入力
4. 「削除」をクリック

---

## 10. CloudWatchロググループ削除

### 10-1. ロググループの削除
1. AWSコンソールで「CloudWatch」を検索して開く
2. 左メニュー「ロググループ」
3. `/ecs/blood-pressure-task` を選択
4. 「アクション」→「ロググループの削除」
5. 「削除」をクリック

---

## 11. 削除確認

### 11-1. 各サービスで削除確認
以下のサービスで、blood-pressureに関連するリソースが残っていないか確認:

- [ ] Route53: ホストゾーン、レコード
- [ ] CloudWatch: アラーム、ダッシュボード、ロググループ
- [ ] ECS: クラスター、サービス、タスク定義
- [ ] EC2: ロードバランサー、ターゲットグループ
- [ ] ECR: リポジトリ、イメージ
- [ ] RDS: データベース、サブネットグループ
- [ ] S3: バケット
- [ ] VPC: VPC、サブネット、セキュリティグループ、NATゲートウェイ、Elastic IP
- [ ] IAM: ロール

### 11-2. コスト確認
1. AWSコンソールで「Billing」を検索
2. 「請求とコスト管理ダッシュボード」を開く
3. 数日後に請求額が0円に近づいていることを確認

---

## トラブルシューティング

### リソースが削除できない場合

#### 1. 依存関係エラー
**エラー**: 「他のリソースに依存しているため削除できません」

**解決方法**:
- 依存しているリソースを先に削除
- 例: ECSサービスを削除してからALBを削除

#### 2. VPC削除エラー
**エラー**: 「VPCにリソースが残っているため削除できません」

**解決方法**:
1. VPC内の全てのリソースを確認:
   - ENI（Elastic Network Interface）
   - セキュリティグループ
   - NATゲートウェイ
2. 残っているリソースを手動で削除
3. 再度VPCの削除を試行

#### 3. セキュリティグループ削除エラー
**エラー**: 「セキュリティグループが使用中です」

**解決方法**:
1. ECSサービスが完全に削除されているか確認
2. ALBが削除されているか確認
3. 数分待ってから再試行

#### 4. RDS削除が遅い
**現象**: RDSの削除に15分以上かかる

**解決方法**:
- 正常な動作です。最終バックアップの作成などで時間がかかります
- ステータスが「削除中」であれば、そのまま待ちます

---

## AWS CLIを使用した一括削除（上級者向け）

### 注意事項
- **実行前に必ずバックアップを取得してください**
- **コマンドを実行する前に内容を確認してください**
- **削除は取り消せません**

### 削除スクリプト

```bash
#!/bin/bash

# リージョン設定
REGION="ap-northeast-1"

echo "=== AWSリソース削除開始 ==="

# 1. ECSサービス削除
echo "1. ECSサービスを削除中..."
aws ecs update-service \
  --cluster blood-pressure-cluster \
  --service blood-pressure-service \
  --desired-count 0 \
  --region $REGION

aws ecs delete-service \
  --cluster blood-pressure-cluster \
  --service blood-pressure-service \
  --force \
  --region $REGION

echo "ECSサービスの削除を待機中（60秒）..."
sleep 60

# 2. ECSクラスター削除
echo "2. ECSクラスターを削除中..."
aws ecs delete-cluster \
  --cluster blood-pressure-cluster \
  --region $REGION

# 3. ALB削除
echo "3. ALBを削除中..."
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --names blood-pressure-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text \
  --region $REGION)

aws elbv2 delete-load-balancer \
  --load-balancer-arn $ALB_ARN \
  --region $REGION

echo "ALBの削除を待機中（60秒）..."
sleep 60

# 4. ターゲットグループ削除
echo "4. ターゲットグループを削除中..."
TG_ARN=$(aws elbv2 describe-target-groups \
  --names blood-pressure-tg \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text \
  --region $REGION)

aws elbv2 delete-target-group \
  --target-group-arn $TG_ARN \
  --region $REGION

# 5. ECRイメージ・リポジトリ削除
echo "5. ECRリポジトリを削除中..."
aws ecr delete-repository \
  --repository-name blood-pressure-app \
  --force \
  --region $REGION

# 6. RDS削除
echo "6. RDSインスタンスを削除中..."
aws rds delete-db-instance \
  --db-instance-identifier blood-pressure-db \
  --skip-final-snapshot \
  --delete-automated-backups \
  --region $REGION

echo "RDSの削除を待機中（600秒）..."
sleep 600

# 7. DBサブネットグループ削除
echo "7. DBサブネットグループを削除中..."
aws rds delete-db-subnet-group \
  --db-subnet-group-name blood-pressure-db-subnet-group \
  --region $REGION

# 8. S3バケット削除
echo "8. S3バケットを削除中..."
BUCKET_NAME=$(aws s3 ls | grep blood-pressure-app-assets | awk '{print $3}')
aws s3 rm s3://$BUCKET_NAME --recursive
aws s3 rb s3://$BUCKET_NAME --force

# 9. NATゲートウェイ削除
echo "9. NATゲートウェイを削除中..."
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=blood-pressure-vpc" \
  --query 'Vpcs[0].VpcId' \
  --output text \
  --region $REGION)

NAT_GW_ID=$(aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" \
  --query 'NatGateways[0].NatGatewayId' \
  --output text \
  --region $REGION)

aws ec2 delete-nat-gateway \
  --nat-gateway-id $NAT_GW_ID \
  --region $REGION

echo "NATゲートウェイの削除を待機中（120秒）..."
sleep 120

# 10. Elastic IP解放
echo "10. Elastic IPを解放中..."
ALLOCATION_ID=$(aws ec2 describe-addresses \
  --filters "Name=domain,Values=vpc" \
  --query 'Addresses[0].AllocationId' \
  --output text \
  --region $REGION)

aws ec2 release-address \
  --allocation-id $ALLOCATION_ID \
  --region $REGION

# 11. VPC削除
echo "11. VPCを削除中..."
aws ec2 delete-vpc \
  --vpc-id $VPC_ID \
  --region $REGION

# 12. CloudWatchロググループ削除
echo "12. CloudWatchロググループを削除中..."
aws logs delete-log-group \
  --log-group-name /ecs/blood-pressure-task \
  --region $REGION

echo "=== AWSリソース削除完了 ==="
echo "IAMロールは手動で削除してください"
```

### スクリプトの使用方法

1. 上記のスクリプトを `delete_aws_resources.sh` として保存
2. 実行権限を付与:
   ```bash
   chmod +x delete_aws_resources.sh
   ```
3. 実行:
   ```bash
   ./delete_aws_resources.sh
   ```

---

## 完了

全てのリソースが削除されました。

### 最終確認事項
- [ ] AWS請求ダッシュボードで今後の請求が発生しないことを確認
- [ ] 必要なデータのバックアップを取得済み
- [ ] IAMユーザーのアクセスキーを無効化（必要に応じて）

お疲れ様でした！
