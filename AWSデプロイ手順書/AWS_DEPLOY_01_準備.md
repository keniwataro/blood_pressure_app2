# AWSデプロイ手順 Part 1: 事前準備

## 目次
1. AWSアカウント設定
2. IAMユーザー作成
3. AWS CLIインストール
4. 必要なツールのインストール

---

## 1. AWSアカウント設定

### 1-1. ルートユーザーのMFA設定（必須）
1. AWSマネジメントコンソールにログイン: https://console.aws.amazon.com/
2. 右上のアカウント名をクリック → 「セキュリティ認証情報」
3. 「多要素認証 (MFA)」セクションで「MFAの有効化」をクリック
4. 「仮想MFAデバイス」を選択
5. スマホに「Google Authenticator」または「Microsoft Authenticator」アプリをインストール
6. QRコードをスキャンして、2つの連続したMFAコードを入力
7. 「MFAの割り当て」をクリック

---

## 2. IAMユーザー作成（推奨）

### 2-1. 管理者IAMユーザーの作成
1. AWSコンソールで「IAM」を検索して開く
2. 左メニュー「ユーザー」→「ユーザーを作成」
3. ユーザー名: `admin-user`（任意）
4. 「AWS マネジメントコンソールへのユーザーアクセスを提供する」に**チェック**
5. 「IAMユーザーを作成します」を選択
6. パスワード設定:
   - 「カスタムパスワード」を選択して強力なパスワードを設定
   - 「ユーザーは次回のサインイン時に新しいパスワードを作成する必要があります」の**チェックを外す**
7. 「次へ」をクリック
8. 「ポリシーを直接アタッチする」を選択
9. 「AdministratorAccess」にチェック
10. 「次へ」→「ユーザーの作成」

### 2-2. IAMユーザーのアクセスキー作成
1. 作成したユーザーをクリック
2. 「セキュリティ認証情報」タブ
3. 「アクセスキーを作成」をクリック
4. 「コマンドラインインターフェイス (CLI)」を選択
5. 確認チェックボックスにチェック → 「次へ」
6. 「アクセスキーを作成」
7. **重要**: アクセスキーIDとシークレットアクセスキーをメモ（後で使用）
8. CSVファイルをダウンロードして安全な場所に保存

---

## 3. AWS CLIインストール

### 3-1. Linux環境でのインストール
```bash
# AWS CLI v2のインストール
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# インストール確認
aws --version
```

### 3-2. AWS CLIの設定
```bash
aws configure
```

以下を入力:
- **AWS Access Key ID**: 先ほどメモしたアクセスキーID
- **AWS Secret Access Key**: シークレットアクセスキー
- **Default region name**: `ap-northeast-1`（東京リージョン）
- **Default output format**: `json`

### 3-3. 設定確認
```bash
aws sts get-caller-identity
```

正常に設定されていれば、アカウント情報が表示されます。

---

## 4. 必要なツールのインストール

### 4-1. Docker（既にインストール済みの場合はスキップ）
docker desktopを起動してから、下記のコマンドで確認
```bash
# Dockerのバージョン確認
docker --version
docker-compose --version
```

### 4-2. jqのインストール（JSON処理用）
```bash
sudo apt-get update
sudo apt-get install -y jq
```

---

## 次のステップ

準備が完了したら、次のファイル「AWS_DEPLOY_02_VPC構築.md」に進んでください。
