SimpleCov.start 'rails' do
  # カバレッジの最低閾値を設定
  minimum_coverage 80
  
  # カバレッジチェックを有効化
  minimum_coverage_by_file 70
  
  # ブランチカバレッジを有効化
  enable_coverage :branch
  minimum_coverage branch: 70
  
  # 除外するディレクトリ・ファイルを指定
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
  add_filter '/db/'
  add_filter '/bin/'
  add_filter 'application_job.rb'
  add_filter 'application_record.rb'
  add_filter 'application_mailer.rb'
  add_filter 'application_cable/'
  
  # グループ化してレポートを整理
  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Helpers', 'app/helpers'
  add_group 'Mailers', 'app/mailers'
  add_group 'Jobs', 'app/jobs'
  add_group 'Libraries', 'lib'
  
  # 結果の出力ディレクトリを指定
  coverage_dir 'coverage'
  
  # 複数のフォーマッタを有効化
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::SimpleFormatter
  ])
end
