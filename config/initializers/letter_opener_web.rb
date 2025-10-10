# Letter Opener Web の設定
if Rails.env.development?
  # メール保存場所の設定
  LetterOpenerWeb.configure do |config|
    config.letters_location = Rails.root.join('tmp', 'letter_opener')
  end
end
