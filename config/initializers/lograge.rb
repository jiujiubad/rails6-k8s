# lograge 使用技巧：https://ruby-china.org/topics/34663
Rails.application.configure do
  # 把每笔日志显示为一行
  config.lograge.enabled = true

  # HTTP 状态为 200-299 的日志，只显示一次
  i = 0
  config.lograge.ignore_custom = lambda do |e|
    if (200..299).to_a.include? e.payload[:status].try(:to_i)
      i += 1
      return true if i > 1
    end
  end
end
