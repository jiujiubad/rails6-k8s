require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Rails6K8s
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # 默认时区
    config.time_zone = "Beijing"
    # 队列适配器
    config.active_job.queue_adapter = :sidekiq
  end
end
