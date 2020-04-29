namespace :db do
  desc "只有在任务从未被调用时才调用 db:prepare 任务"
  task prepare_if_not_yet: [:environment] do
    begin
      if !ActiveRecord::SchemaMigration.table_exists?
        # 数据库存在，但表不存在
        Rake::Task["db:prepare"].invoke
        exit 0
      end
    rescue ActiveRecord::NoDatabaseError
      # 数据库不存在
      Rake::Task["db:prepare"].invoke
      exit 0
    end
  end

  desc "等待 db:prepare 任务完成"
  task wait_for_prepare_completion: [:environment] do
    loop do
      begin
        if !ActiveRecord::InternalMetadata.table_exists?
          # 数据库存在，但表不存在
          sleep 1
        elsif !ActiveRecord::InternalMetadata.where(key: :environment).exists?
          # 表存在，但安装尚未完成
          sleep 1
        else
          break
        end
      rescue ActiveRecord::NoDatabaseError
        # 数据库不存在
        sleep 1
      end
    end
  end

  desc "调用 db:migrate 任务并忽略并行执行引起的错误"
  task try_migrate: [:wait_for_prepare_completion] do
    begin
      Rake::Task["db:migrate"].invoke
    rescue ActiveRecord::ConcurrentMigrationError => e
      Rails.logger.info "跳过 migrate 迁移，因为另一个 migrate 进程正在运行"
    end
  end
end
