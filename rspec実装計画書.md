# RSpec実装計画書

## 概要

このドキュメントは、血圧管理アプリケーションのRSpecテスト実装計画をまとめたものです。
現在、基本的なテストファイルは作成されていますが、実装が不十分な状態です。
Docker環境での開発を考慮し、段階的にテストを実装していきます。

## プロジェクト概要

- **アプリケーション**: 血圧管理システム
- **技術スタック**: Ruby on Rails 7.1.5.2, PostgreSQL, Devise認証
- **開発環境**: Docker + Docker Compose
- **テストフレームワーク**: RSpec 6.0.0, FactoryBot, Capybara

## 主要機能とテスト対象

### 1. 認証・認可システム (Devise)
- ユーザー登録・ログイン・ログアウト
- 役割ベースアクセス制御 (患者/医療従事者/システム管理者)
- 病院・役割の関連付け

### 2. 血圧記録管理
- CRUD操作 (作成/読み取り/更新/削除)
- CSVインポート機能
- データ検証

### 3. ユーザー管理
- プロフィール管理
- 役割切り替え機能
- 患者-スタッフ割り当て

### 4. 管理者機能
- ユーザー管理
- 病院管理
- システム設定

### 5. レポート・チャート機能
- 血圧データのグラフ表示
- データ集計・分析

## テスト環境設定

### Docker環境でのテスト実行

```bash
# テスト環境でのコンテナ起動
docker-compose run --rm web bundle exec rails db:create RAILS_ENV=test
docker-compose run --rm web bundle exec rails db:migrate RAILS_ENV=test
docker-compose run --rm web bundle exec rails db:seed RAILS_ENV=test

# RSpec実行
docker-compose run --rm web bundle exec rspec

# 特定ファイルの実行
docker-compose run --rm web bundle exec rspec spec/models/user_spec.rb

# カバレッジレポート生成
docker-compose run --rm web bundle exec rspec --format html --out coverage/index.html
```

### RSpec設定の見直し

- `spec/rails_helper.rb`: FactoryBot, Database Cleaner設定済み
- `spec/spec_helper.rb`: 基本設定
- SimpleCovによるカバレッジ計測設定済み

## テスト実装計画

### Phase 1: 基盤整備 (1-2週間)

#### 1.1 Factory実装
**目標**: すべてのモデルに対するFactoryを作成し、テストデータの作成を効率化

**対象ファイル**:
- `spec/factories/users.rb` - ユーザーFactory (患者/医療従事者/管理者)
- `spec/factories/roles.rb` - 役割Factory
- `spec/factories/hospitals.rb` - 病院Factory
- `spec/factories/user_hospital_roles.rb` - ユーザー役割関連Factory
- `spec/factories/blood_pressure_records.rb` - 血圧記録Factory
- `spec/factories/patient_staff_assignments.rb` - 患者スタッフ割り当てFactory

**実装内容**:
- 各Factoryに必要な属性と関連付け
- バリデーションを考慮したデータ生成
- Faker gemを使用したランダムデータ生成
- Traitを使用した条件分岐 (例: :admin, :patient, :medical_staff)

#### 1.2 サポートモジュール作成
**目標**: 共通のテストヘルパーとユーティリティを作成

**対象ファイル**:
- `spec/support/authentication_helper.rb` - 認証ヘルパー
- `spec/support/authorization_helper.rb` - 認可ヘルパー
- `spec/support/factory_bot_helper.rb` - Factory拡張ヘルパー
- `spec/support/database_cleaner.rb` - DBクリーンアップ設定

### Phase 2: モデルテスト実装 (2-3週間)

#### 2.1 Userモデルテスト
**ファイル**: `spec/models/user_spec.rb`
**テスト項目**:
- バリデーション (email, user_id, password)
- アソシエーション (has_many, belongs_to)
- メソッド (current_role, has_role?, etc.)
- Devise関連機能

#### 2.2 Roleモデルテスト
**ファイル**: `spec/models/role_spec.rb`
**テスト項目**:
- バリデーション (name一意性)
- スコープメソッド (medical_staff, hospital_roles)
- アソシエーション

#### 2.3 Hospitalモデルテスト
**ファイル**: `spec/models/hospital_spec.rb`
**テスト項目**:
- バリデーション
- アソシエーション
- システム病院の特別扱い

#### 2.4 UserHospitalRoleモデルテスト
**ファイル**: `spec/models/user_hospital_role_spec.rb`
**テスト項目**:
- 複合ユニーク制約
- 権限レベル管理
- アソシエーション

#### 2.5 BloodPressureRecordモデルテスト
**ファイル**: `spec/models/blood_pressure_record_spec.rb`
**テスト項目**:
- バリデーション (血圧値の範囲)
- アソシエーション
- カスタムメソッド

#### 2.6 PatientStaffAssignmentモデルテスト
**ファイル**: `spec/models/patient_staff_assignment_spec.rb`
**テスト項目**:
- 複合ユニーク制約
- アソシエーション
- 割り当てロジック

### Phase 3: リクエストテスト実装 (3-4週間)

#### 3.1 認証関連テスト
**ファイル**: `spec/requests/authentication_spec.rb`
**テスト項目**:
- ログイン/ログアウト
- パスワードリセット
- セッション管理

#### 3.2 血圧記録CRUDテスト
**ファイル**: `spec/requests/blood_pressure_records_spec.rb`
**テスト項目**:
- 認証済みユーザーのみアクセス可能
- CRUD操作の正常系/異常系
- CSVインポート機能
- 権限チェック (患者のみ自分の記録を操作可能)

#### 3.3 プロフィール管理テスト
**ファイル**: `spec/requests/profiles_spec.rb`
**テスト項目**:
- プロフィール表示/編集/更新
- 認証チェック
- バリデーション

#### 3.4 管理者機能テスト
**ファイル**: `spec/requests/admin/users_spec.rb`
**ファイル**: `spec/requests/admin/hospitals_spec.rb`
**テスト項目**:
- 管理者権限チェック
- ユーザー管理機能
- 病院管理機能

#### 3.5 医療従事者機能テスト
**ファイル**: `spec/requests/medical_staff/dashboard_spec.rb`
**ファイル**: `spec/requests/medical_staff/patients_spec.rb`
**ファイル**: `spec/requests/medical_staff/staff_spec.rb`
**テスト項目**:
- 医療従事者権限チェック
- 患者管理機能
- スタッフ割り当て機能

#### 3.6 レポート機能テスト
**ファイル**: `spec/requests/charts_spec.rb`
**テスト項目**:
- チャート表示
- データ集計
- アクセス権限

### Phase 4: システムテスト実装 (2-3週間)

#### 4.1 統合フロー
**ファイル**: `spec/system/user_journey_spec.rb`
**テスト項目**:
- 患者ユーザー: 登録 → ログイン → 血圧記録 → プロフィール編集
- 医療従事者: ログイン → 患者割り当て → 記録確認
- 管理者: ログイン → ユーザー管理 → 病院管理

#### 4.2 エラー処理
**ファイル**: `spec/system/error_handling_spec.rb`
**テスト項目**:
- 404/500エラー処理
- 権限エラー時のリダイレクト
- バリデーションエラーの表示

### Phase 5: ヘルパーとビューテスト (1-2週間)

#### 5.1 ヘルパーテスト
**対象**: `spec/helpers/*_helper_spec.rb`
- ApplicationHelper
- BloodPressureRecordsHelper
- ChartsHelper
- DashboardHelper
- HospitalsHelper
- MedicalStaffHelper
- ProfilesHelper

#### 5.2 ビューテスト
**対象**: `spec/views/**/*.erb_spec.rb`
- 主要ビューの表示テスト
- 部分テンプレートのテスト

## テスト品質基準

### カバレッジ目標
- **全体カバレッジ**: 90%以上
- **モデルカバレッジ**: 95%以上
- **コントローラーカバレッジ**: 85%以上
- **ヘルパーカバレッジ**: 80%以上

### テスト設計原則
1. **Given-When-Thenパターン**を使用
2. **1つのテストは1つのことを検証**
3. **DRY原則**: 共通処理はヘルパーやshared examplesを使用
4. **テストデータの独立性**: Factoryを使用し、fixtureに依存しない
5. **高速実行**: 不要なDBアクセスを避ける

### CI/CD連携
- GitHub Actionsでの自動テスト実行
- カバレッジレポートの自動生成
- テスト失敗時の通知

## 実装時の注意事項

### 1. Docker環境考慮
- データベース接続は`DATABASE_URL`環境変数を使用
- テスト実行時は`RAILS_ENV=test`を設定
- コンテナ内でのファイルパスに注意

### 2. 認証・認可の複雑さ
- 役割ベースのアクセス制御を徹底的にテスト
- 各テストで適切なユーザー権限を設定
- エッジケース（権限のないユーザーのアクセス）をカバー

### 3. 非同期処理
- メール送信などの非同期処理は適切にモック化
- ActiveJobのテストは分離して実行

### 4. データ整合性
- 外部キー制約を考慮したテストデータ作成
- ユニーク制約のテスト
- 関連データの依存関係テスト

## スケジュールとマイルストーン

### Week 1-2: Phase 1 (基盤整備)
- Factory実装完了
- サポートモジュール作成
- 基本的なテスト実行環境確認

### Week 3-5: Phase 2 (モデルテスト)
- 全モデルテスト実装完了
- モデルカバレッジ95%以上達成

### Week 6-9: Phase 3 (リクエストテスト)
- 全リクエストテスト実装完了
- 主要APIエンドポイントのカバー

### Week 10-12: Phase 4 (システムテスト)
- 主要ユーザーJourneyのテスト完了
- エラー処理テスト完了

### Week 13-14: Phase 5 (残作業)
- ヘルパー/ビューテスト完了
- 全体カバレッジ90%以上達成

### Week 15: 最終調整
- リファクタリング
- ドキュメント更新
- CI/CD設定

## リスクと対策

### 技術的リスク
1. **複雑な役割ベース認証**: 各テストで適切な権限設定を徹底
2. **Docker環境依存**: ローカル開発環境でもテスト実行可能にする
3. **データベース制約**: Factoryで制約を満たすデータ生成を徹底

### プロジェクトリスク
1. **スケジュール遅延**: フェーズごとにMVPを定義し、段階的に進める
2. **品質低下**: コードレビューの実施と自動テスト導入
3. **技術的負債**: リファクタリング期間を確保

## 成功基準

1. **機能カバー率**: 全主要機能のテスト実装完了
2. **コードカバー率**: 90%以上の達成
3. **CI/CD**: 自動テスト実行環境の構築
4. **保守性**: テストコードの可読性と保守性の確保
5. **実行速度**: 全テスト5分以内で完了

## 参考資料

- [RSpec Rails Documentation](https://rspec.info/documentation/)
- [Factory Bot Documentation](https://github.com/thoughtbot/factory_bot)
- [Capybara Documentation](https://github.com/teamcapybara/capybara)
- [Rails Testing Guide](https://guides.rubyonrails.org/testing.html)
