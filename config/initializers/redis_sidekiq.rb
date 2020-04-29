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
