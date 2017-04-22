require 'bundler'
require 'capybara/poltergeist'

require './board'

Bundler.require
Dotenv.load

# client = HTTPClient.new('https://a-rakumo.appspot.com/')

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {})
end

session = Capybara::Session.new :poltergeist
session.visit 'https://a-rakumo.appspot.com/login?app=board&next=%2Fboard'

# rakumo login
session.fill_in 'domainTextBox', with: ENV['GOOGLE_APPS_DOMAIN']
session.click_button 'loginButton'

sleep 1

# Google login
session.fill_in 'Email', with: ENV['GOOGLE_APPS_EMAIL']
session.click_button 'next'

sleep 1

session.fill_in 'Passwd', with: ENV['GOOGLE_APPS_PASSWD']
session.click_button 'signIn'

sleep 1

# Google 2FA
totp = ROTP::TOTP.new ENV['TOTP_SECRET'], issuer: ENV['TOTP_ISSUER']
session.fill_in 'totpPin', with: totp.now
session.click_button 'submit'

sleep 1

# rakumo board

#  5: インデックス
#  6: ワークスタイル(社員)
#  7: ワークスタイル(バイト・パート)
#  8: オフィスガイドライン
#  9: 社内制度・イベント
# 10: 福利厚生
# 11: 管理部門への依頼
# 12: システム・ツール
# 13: 組織情報
boards = []
(5..13).each do |i|
  session.find("#fasti_board_widgets_layout_ScrollingTabController_0_fasti_board_views_BoardView_#{i}").click

  sleep 10

  doc = Nokogiri::HTML session.html.force_encoding 'utf-8'
  boards << doc.css("div[aria-labelledby='fasti_board_widgets_layout_ScrollingTabController_0_fasti_board_views_BoardView_#{i}'] .postSummaryView").map { |elm| Board.parse elm }
end

texts = boards.flatten.keep_if { |b| b.recent? 1 }.map(&:to_human)

return if texts.empty?

notifier = Slack::Notifier.new ENV['SLACK_INCOMING_URL'], channel: ENV['SLACK_CHANNEL']

notifier.ping <<~EOS
  ```
  *** Rakumo Board 昨日からの更新 ***
  #{texts.join "\n"}
  ```
EOS
