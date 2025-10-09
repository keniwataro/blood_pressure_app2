# 血圧管理アプリケーション

Rails 7 + PostgreSQL + Docker環境で構築された、患者・医療従事者・システム管理者による役割分担型の血圧管理システムです。

## 特徴

### 🎯 役割分担システム
- **患者**: 血圧記録の入力・閲覧
- **医療従事者**: 患者管理、血圧記録管理、病院管理
- **システム管理者**: 全ユーザー・病院・役割の管理

### 📊 主な機能
- 血圧記録の登録・編集・削除・一覧表示
- 血圧推移グラフ表示（Chart.js使用）
- 患者管理（医療従事者による）
- 病院管理
- ユーザー管理（システム管理者による）
- 役割・権限管理
- 確認画面付きの安全なデータ操作

### 🏗️ 技術構成
- **Backend**: Ruby on Rails 7.1.5.2
- **Database**: PostgreSQL
- **Frontend**: Bootstrap 5, Chart.js, Hotwire/Turbo
- **Authentication**: Devise
- **Container**: Docker & Docker Compose
- **Testing**: RSpec（準備中）

## セットアップ方法

### 前提条件
- Docker & Docker Compose がインストールされていること

### インストール手順

1. リポジトリをクローン
```bash
git clone <repository-url>
cd 血圧管理app3
```

2. Docker Compose でアプリケーションを起動
```bash
docker-compose up -d
```

3. データベースのセットアップ
```bash
docker-compose exec web rails db:create
docker-compose exec web rails db:migrate
docker-compose exec web rails db:seed
```

4. ブラウザでアクセス
```
http://localhost:3000
```

### 初期データ
- システム管理者アカウントが作成されます
- サンプル病院、ユーザー、役割データが投入されます

## 利用方法

### ログイン情報（初期データ）
- **システム管理者**:
  - ユーザーID: admin
  - パスワード: password123

### 主な画面
- `/` - トップページ（ログイン画面へリダイレクト）
- `/admin` - システム管理者ダッシュボード
- `/medical_staff` - 医療従事者ダッシュボード
- `/patient` - 患者ダッシュボード

## 開発者向け情報

### ローカル開発環境
```bash
# Railsサーバー起動
docker-compose exec web rails s

# コンソール起動
docker-compose exec web rails c

# テスト実行
docker-compose exec web rails test
```

### 主要なGem
- `devise` - ユーザー認証
- `kaminari` - ページネーション
- `chart-js-rails` - グラフ表示
- `bootstrap` - UIフレームワーク

### アーキテクチャ
- **MVCアーキテクチャ**（Rails標準）
- **Namespace別コントローラー**（admin, medical_staff, patient）
- **Enumを使用した権限管理**
- **多対多関連**（ユーザー ↔ 役割 ↔ 病院）

## プロジェクト構造

```
app/
├── controllers/
│   ├── admin/          # システム管理者機能
│   ├── medical_staff/  # 医療従事者機能
│   └── patient/        # 患者機能
├── models/             # データモデル
├── views/              # ビュー
└── assets/             # アセット

db/
├── migrate/            # マイグレーション
└── seeds.rb            # 初期データ

config/
├── routes.rb           # ルーティング
└── database.yml        # DB設定
```

## セキュリティ

- **Devise認証**: パスワード暗号化、セッション管理
- **権限ベースアクセス制御**: 各役割に応じたアクセス制限
- **CSRF対策**: Rails標準のCSRFトークン
- **XSS対策**: Rails標準のHTMLエスケープ

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

## 貢献

1. Fork it
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 連絡先

プロジェクトに関する質問やフィードバックは、issueを作成してください。
