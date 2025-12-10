# AWSデプロイ手順 Part 4: ECR・S3構築

## 目次
1. ECRリポジトリ作成
2. S3バケット作成
3. Dockerイメージのビルドとプッシュ

---

## 1. ECRリポジトリ作成

### 1-1. ECRリポジトリの作成
1. AWSコンソールで「Elastic Container Registry」を検索して開く
2. 「リポジトリを作成」をクリック
3. 以下を設定:
   
   **一般設定**
   - **リポジトリ名**: `blood-pressure-app`
   
   **イメージタグ設定**
   - **イメージタグのミュータビリティ**: **Mutable**（イメージタグは上書きできます）を選択
   
   **暗号化設定**
   - **暗号化タイプ**: AES-256（デフォルト）

4. 「リポジトリを作成」をクリック

### 1-2. リポジトリURIの確認
1. 作成したリポジトリをクリック
2. **リポジトリURI**をメモ:
   ```
   123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/blood-pressure-app
   ```

---

## 2. S3バケット作成

### 2-1. S3バケットの作成
1. AWSコンソールで「S3」を検索して開く
2. 「バケットを作成」をクリック
3. 以下を設定:

   **一般的な設定**
   - **AWS リージョン**: アジアパシフィック（東京）ap-northeast-1
   - **バケットタイプ**: 汎用（デフォルト）
   - **バケット名**: `blood-pressure-app-assets-<ランダム文字列>`
     - 例: `blood-pressure-app-assets-20251018`
     - ※バケット名は全世界で一意である必要があります
   
   **オブジェクト所有者**
   - **ACL 無効（推奨）**を選択（デフォルト）
   - オブジェクト所有者: バケット所有者の強制
   
   **このバケットのブロックパブリックアクセス設定**
   - **「パブリックアクセスをすべてブロック」のチェックを外す**
   - 警告メッセージが表示されるので、確認のチェックボックスにチェックを入れる
   
   **バケットのバージョニング**
   - **無効にする**を選択（デフォルト）
   
   **デフォルトの暗号化**
   - **暗号化タイプ**: Amazon S3 マネージドキーを使用したサーバー側の暗号化（SSE-S3）を選択（デフォルト）
   - **バケットキー**: 有効にする（デフォルト）
   
   **詳細設定**
   - **オブジェクトロック**: 無効にする（デフォルト）

4. 「バケットを作成」をクリック

### 2-2. バケットポリシーの設定
1. 作成したバケットをクリック
2. 「アクセス許可」タブ
3. 「バケットポリシー」→「編集」
4. 以下のポリシーを貼り付け:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::blood-pressure-app-assets-20251018/*"
    }
  ]
}
```

**重要: `blood-pressure-app-assets-20251018` の部分を、手順2-1で作成した実際のバケット名に置き換えてください。**

5. 「変更を保存」

### 2-3. CORSの設定
1. 「アクセス許可」タブ
2. 「クロスオリジンリソース共有 (CORS)」→「編集」
3. 以下を貼り付け:

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedOrigins": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3000
  }
]
```

4. 「変更を保存」

---

## 3. Dockerイメージのビルドとプッシュ

### 3-1. ECRへのログイン
```bash
# プロジェクトディレクトリに移動
cd /home/iwasaki/blood_pressure_app2

# ECRにログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com
```



**※ `123456789012` は自分のAWSアカウントIDに置き換えてください**

### 3-2. 本番用Dockerfileの作成
プロジェクトルートに `Dockerfile.production` を作成:

```dockerfile
FROM ruby:3.3.9-slim

RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev libyaml-dev nodejs npm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

COPY . .

ENV RAILS_ENV=production
ENV SECRET_KEY_BASE=dummy_secret_key_base_for_precompile
RUN bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

### 3-3. Dockerイメージのビルド
```bash
docker build -f Dockerfile.production -t blood-pressure-app:latest .
```

### 3-4. イメージのタグ付け
```bash
docker tag blood-pressure-app:latest 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/blood-pressure-app:latest
```

### 3-5. ECRへプッシュ
```bash
docker push 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/blood-pressure-app:latest
```

**※ `123456789012` は自分のAWSアカウントIDに置き換えてください**

**プッシュには数分かかります。**

### 3-6. プッシュ確認
1. AWSコンソールのECRに戻る
2. `blood-pressure-app` リポジトリをクリック
3. `latest` タグのイメージが表示されていることを確認

---

## 次のステップ

ECR・S3構築が完了したら、次のファイル「AWS_DEPLOY_05_ECS構築.md」に進んでください。
