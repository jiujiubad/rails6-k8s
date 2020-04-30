source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails'
gem 'puma'
gem 'pg'
gem 'sass-rails'
gem 'webpacker'
gem 'turbolinks'
gem 'jbuilder'
gem 'bootsnap'
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "figaro"
gem 'redis'
gem 'sidekiq'
gem 'sidekiq-cron'
gem 'okcomputer'  #健康检查
gem 'lograge'  #管理Rails日志

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'pry-rails'     #替代 rails c
  gem 'pry-byebug' #使用 continue/next/finish/step
end

group :development do
  gem 'web-console'
  gem 'listen'
  gem 'spring'
  gem 'spring-watcher-listen'
  gem 'socksify' #socks5 代理
end

group :test do
  gem 'capybara'
  gem 'webdrivers'
  gem 'minitest-reporters'
  gem 'guard'
  gem 'guard-minitest'
  gem 'rails-controller-testing'
end
