

## Rails Scaffold

```
bundle 
rails g scaffold Chat  message:string
rails db:migrate
```

config/routes.rb

```
root 'chats#new'
```

执行，打开 <http://localhost:3000>

```
rails s
```

## 数据库改用 pg

Gemfile

```
gem 'pg'
```

```
bundle update
```

config/database.yml

```
default: &default
  adapter: postgresql
  encoding: utf-8
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: <%= ENV.fetch("POSTGRES_HOST") { "0.0.0.0" } %>
  port: <%= ENV.fetch("POSTGRES_PORT") { 5432 } %>
  username: <%= ENV["POSTGRES_USER"] %>
  password: <%= ENV["POSTGRES_PASSWORD"] %>

development:
  <<: *default
  database: rails6_k8s_development

test:
  <<: *default
  database: rails6_k8s_test

production:
  <<: *default
  database: rails6_k8s_production
```

figaro

```
bundle exec figaro install
```

config/application.yml

```
POSTGRES_USER: yourName
POSTGRES_PASSWORD: yourPword
```

执行，然后打开 <http://localhost3000>

```
rails db:migrate:reset
rails s
```

## ActionCable 聊天室 - 环境准备

Gemfile 加入并执行 `bundle`

```
gem 'redis'
gem 'sidekiq'
gem 'sidekiq-cron'
```

config/routes.rb

```
require 'sidekiq/web'
mount Sidekiq::Web, at: '/sidekiq'
```

config/application.rb 把队列适配器改为 sidekiq

```
# 默认时区
config.time_zone = "Beijing"
# 队列适配器
config.active_job.queue_adapter = :sidekiq
```

config/initializers/redis_sidekiq.rb 初始化 redis 和 sidekiq

```
require 'sidekiq/web'
require 'sidekiq/cron/web'

# 使用 heroku 时，插件 REDISTOGO 默认识别 ENV["REDISTOGO_URL"]
url = ENV['REDISTOGO_URL']? ENV['REDISTOGO_URL'] : ENV.fetch('REDIS_URL') { 'redis://localhost:6379/' }

sidekiq_url = "#{url}0"
redis_url = "#{url}1"

$redis = Redis.new(url: redis_url)

# sidekiq 服务端和 redis 的连接
# logger levels 日志等级：DEBUG、INFO、WARN、ERROR、FATAL、UNKNOWN
Sidekiq.configure_server do |config|
  config.redis = { url: sidekiq_url  }
  config.logger.level = Logger::INFO
  config.average_scheduled_poll_interval = 1

  # sidekiq-cron 加载配置文件（用到了再创建，否则报错 undefined method `inject' for false:FalseClass）
  schedule_file = "config/schedule.yml"
  if File.exist?(schedule_file) && Sidekiq.server?
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end
end

# sidekiq 客户端和 redis 的连接
Sidekiq.configure_client do |config|
  config.redis = { url: sidekiq_url }
end

# sidekiq web 权限：如账号密码
Sidekiq::Web.use(Rack::Auth::Basic) do |username, password|
  [username, password] == [ENV['SIDEKIQ_USERNAME'], ENV['SIDEKIQ_PASSWORD']]
end

# sidekiq-cron 轮询间隔（默认每 30 秒钟检查一次任务）
Sidekiq.options[:poll_interval]         = 1
Sidekiq.options[:poll_interval_average] = 1
```

config/sidekiq.yml

```
---
concurrency: <%= ENV.fetch("SIDEKIQ_CONCURRENCY") { 20 }.to_i %>
:pidfile: ./tmp/pids/sidekiq.pid
:logfile: ./log/sidekiq.log
:queues:
  - [alone,   <%= ENV.fetch("SIDEKIQ_QUEUES_ALONE") { 1 }.to_i %>]
  - [default, <%= ENV.fetch("SIDEKIQ_QUEUES_DEFAULT") { 5 }.to_i %>]
  - [normal,  <%= ENV.fetch("SIDEKIQ_QUEUES_NORMAL") { 10 }.to_i %>]
```

config/cable.yml 修改适配器为 redis

```
development:
  adapter: redis
  url: <%= ENV['REDISTOGO_URL'] || ENV.fetch('REDIS_URL') { 'redis://localhost:6379/' } %>

test:
  adapter: test

production:
  adapter: redis
  url: <%= ENV['REDISTOGO_URL'] || ENV.fetch('REDIS_URL') { 'redis://localhost:6379/' } %>
  channel_prefix: rails6_production
```

## ActionCable 聊天室 - 功能

```
rails g channel chat
rails g job chat
```

app/channels/chat_channel.rb

```
def subscribed
  stream_from "chat_channel"
end
```

app/controllers/chats_controller.rb

```
  def new
    @chat = Chat.new
    @chats = Chat.all
  end

  def create
    @chat = Chat.new(chat_params)

    respond_to do |format|
      if @chat.save
        ChatJob.set(wait: 2.seconds).perform_later(@chat.message)
        format.js
      else
        format.html { render :new }
      end
    end
  end
```

app/jobs/chat_job.rb

```
def perform(*args)
  puts "环境：#{ENV['RAILS_ENV']}"
  ActionCable.server.broadcast 'chat_channel', msg: args[0]
end
```

app/views/chats/new.html.erb

```
<% @chats.each do |chat| %>
  <%= chat.message %> |
<% end %>
<span id="new_message"></span>
```

app/javascript/channels/chat_channel.js

```
received(data) {
  var node = document.getElementById('new_message');
  node.innerHTML += data['msg'] + ' | ';
}
```

app/views/chats/_form.html.erb

```
- <%= form_with(model: chat, local: true) do |form| %>
+ <%= form_with(model: chat) do |form| %>
```

## ActionCable 聊天室 - 生产环境

config/application.yml

```
# Rails
#允许使用/public的文件
RAILS_SERVE_STATIC_FILES: true
#显示rails s详细日志
RAILS_LOG_TO_STDOUT: true 

# Postgresql
POSTGRES_USER: yourName
POSTGRES_PASSWORD: yourPword

# Redis
REDIS_URL: redis://:yourPword@yourRedisHost:6379/

# Sidekiq
SIDEKIQ_TIMEOUT: 60
SIDEKIQ_CONCURRENCY: "5"
SIDEKIQ_USERNAME: aaron
SIDEKIQ_PASSWORD: foobar
```

执行，打开 <http://localhost:3000> 测试发送消息，延迟两秒出现

```
rails assets:precompile
RAILS_ENV=production bundle exec sidekiq -C config/sidekiq.yml
rails s -e production
```
