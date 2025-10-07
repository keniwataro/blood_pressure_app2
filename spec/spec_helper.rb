# このファイルは`rails generate rspec:install`コマンドによって生成されました。通常、すべての
# specは`spec`ディレクトリの下に存在し、RSpecが`$LOAD_PATH`に追加します。
# 生成された`.rspec`ファイルには`--require spec_helper`が含まれており、これにより
# このファイルは常に読み込まれ、どのファイルでも明示的にrequireする必要がありません。
#
# このファイルは常に読み込まれるため、可能な限り軽量に保つことを推奨します。
# このファイルから重量級の依存関係をrequireすると、個別のファイルがそのすべてを
# 必要としない場合でも、すべてのテスト実行でテストスイートの起動時間が追加されます。
# 代わりに、追加の依存関係をrequireし、追加のセットアップを実行する別のヘルパーファイルを作成し、
# 実際にそれを必要とするspecファイルからのみrequireすることを検討してください。
#
# https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration を参照
RSpec.configure do |config|
  # rspec-expectationsの設定はここに記述します。必要に応じてwrongや
  # stdlib/minitest assertionsなどの代替のアサーション/期待ライブラリを使用できます。
  config.expect_with :rspec do |expectations|
    # このオプションはRSpec 4でデフォルトで`true`になります。カスタムマッチャーの
    # `description`と`failure_message`に、`chain`を使用して定義されたヘルパーメソッドの
    # テキストを含めるようになります。例えば：
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ではなく：
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocksの設定はここに記述します。ここで`mock_with`オプションを変更することで、
  # bogusやmochaなどの代替のテストダブルライブラリを使用できます。
  config.mock_with :rspec do |mocks|
    # 実際のオブジェクトに存在しないメソッドをモックまたはスタブすることを防ぎます。
    # 一般的に推奨され、RSpec 4ではデフォルトで`true`になります。
    mocks.verify_partial_doubles = true
  end

  # このオプションはRSpec 4で`:apply_to_host_groups`がデフォルトになります（オフにする方法はありません。
  # このオプションはRSpec 3での後方互換性のためだけに存在します）。
  # これにより、共有コンテキストのメタデータが一致するメタデータを持つグループでの暗黙の自動包含を
  # トリガーするのではなく、ホストグループと例のメタデータハッシュに継承されます。
  config.shared_context_metadata_behavior = :apply_to_host_groups

# 以下の設定はRSpecでの良好な初期体験を提供するために推奨されますが、
# 必要に応じて自由にカスタマイズしてください。
=begin
  # `:focus`メタデータでタグ付けすることで、関心のある個別のexampleやグループに
  # spec実行を制限できます。何も`:focus`でタグ付けされていない場合、
  # すべてのexampleが実行されます。RSpecはまた`:focus`メタデータを含む
  # `it`、`describe`、`context`のエイリアスを提供します：それぞれ`fit`、`fdescribe`、`fcontext`です。
  config.filter_run_when_matching :focus

  # `--only-failures`および`--next-failure`CLIオプションをサポートするために、
  # RSpecが実行間でいくつかの状態を維持できるようにします。
  # このファイルをソース管理システムで無視するように設定することを推奨します。
  config.example_status_persistence_file_path = "spec/examples.txt"

  # 利用可能な構文を推奨される非モンキーパッチ構文に制限します。
  # 詳細については以下を参照してください：
  # https://rspec.info/features/3-12/rspec-core/configuration/zero-monkey-patching-mode/
  config.disable_monkey_patching!

  # 多くのRSpecユーザーは通常、スイート全体または個別のファイルを実行します。
  # 個別のspecファイルを実行する場合、より詳細な出力を許可すると便利です。
  if config.files_to_run.one?
    # 詳細な出力のためにドキュメンテーションフォーマッターを使用します。
    # フォーマッターが既に設定されていない場合（例: コマンドライン経由）。
    config.default_formatter = "doc"
  end

  # spec実行の終了時に最も遅い10個のexampleとexampleグループを表示し、
  # どのspecが特に遅く実行されているかを明らかにします。
  config.profile_examples = 10

  # 順序依存性を明らかにするためにspecをランダムな順序で実行します。
  # 順序依存性が見つかり、デバッグしたい場合は、各実行後に印刷される
  # seedを提供することで順序を修正できます。
  #     --seed 1234
  config.order = :random

  # `--seed`CLIオプションを使用してこのプロセスでグローバルなランダム化をシードします。
  # これを設定することで、ランダム化に関連するテスト失敗を、同じ`--seed`値を
  # 渡すことで決定論的に再現できます。
  Kernel.srand config.seed
=end
end
