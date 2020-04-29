class ChatJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "环境：#{ENV['RAILS_ENV']}"
    ActionCable.server.broadcast 'chat_channel', msg: args[0]
  end
end
