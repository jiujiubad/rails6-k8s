FROM jiujiubad/rails-base:2.7
LABEL maintainer="jiujiubad@gmail.com"

# 安装 apk（追加需要用到的包）
# RUN apk add --update --no-cache <名称>

# 环境变量可在 .env 文件中定义
# CMD 命令可放在 docker-compose 的 command

WORKDIR /app

# 从其他构建阶段复制文件
# COPY --from=0 /app /app
