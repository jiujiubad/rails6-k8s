## Rails6 Dockerfile 和 docker-compose

使用 docker-compose 开启常用服务：

- Rails 6，基于 ruby:2.7-alpine
- Postgresql 12.2，也支持 mysql、mariadb 数据库
- Redis 5
- Sidekiq 6

基于以下项目改造：

- [ledermann/docker-rails-base 编写 Dockerfile base](https://github.com/ledermann/docker-rails-base)
- [ledermann/docker-rails 编写 Dockerfile final 和 docker-compose](https://github.com/ledermann/docker-rails)

### 复制文件

- bin/k8s 文件夹
- .dockerignore
- .env.example 复制两个，一个改名为 .env
- docker-compose.yml
- Dockerfile
- Dockerfile.base
- lib/tasks/db.rake 和 lib/tasks/sidekiq.rake

### 修改文件

1）bin/k8s/prepare-db 修改数据库 HOST 和端口

2）.gitignore 添加 `/.env`，与 .dockerignore 可继续追加需要忽略的文件或文件夹

3）.env 修改环境变量如 key、host、user、password

4）Dockerfile 修改基础镜像版本号

如需定制基础镜像如 ruby 2.6，修改 Dockerfile.base 的 ruby 镜像版本如 `FROM ruby:2.6-alpine` 和 LABEL 后创建和推送镜像

```
docker build -t jiujiubad/rails-base:2.6 . -f Dockerfile.base
docker push jiujiubad/rails-base:2.6
```

最后修改 Dockerfile FROM 自己的镜像如

```
FROM jiujiubad/rails-base:2.6
```

5）docker-compose.yml 修改

- services 名称以及 container_name，如 <项目名-puma>、<项目名-pg>
- image 镜像标签名，其中 puma 镜像是在本地创建
- volumes，可在 puma 服务上追加挂载文件夹如 `./tmp/uploads:/app/public/uploads`。更多标准镜像的数据文件夹，可以在 [dockerhub](https://hub.docker.com/) 查看镜像说明

如需追加环境变量，写在 .env 中，然后设置 env_file 为 .env

6）本地打开 <http://localhost:3000>

如果 config/environments/production.rb 设置了 `config.force_ssl = true`

- **使用 Firefox 浏览器（推荐）**
- 使用 Chrome 浏览器（会强制重定向 https），要把 `config.force_ssl = true` 暂时注释掉才能打开

### 开始

前期测试问题多不要加 -d 可以实时显示 log，后期测试加 -d 后台显示 log。因为在 compose 中有指定 volumes 挂载文件夹，所以容器数据卷不用保留，关闭容器时指定 -v

```
#开启容器
docker-compose up --build --force-recreate       
docker-compose up -d --build --force-recreate
#关闭容器
docker-compose down -v  #关闭容器（删除关闭的容器、断开compose创建的网络、删除容器数据卷）
```

成功开启所有容器后，就可以打开 <http://localhost:3000>

### 调试

查看日志

```
docker-compose ps                                #查看所有服务状态
docker-compose logs -f <服务名如 rails>   #查看某个服务的log
```

进入镜像以执行命令

```
docker images | grep <name>               #查看镜像
docker run --rm <imageID> ls -a <dir>  #打开容器L
```

进入容器以执行命令

```
docker exec -it <imageID> sh             #进入容器（有的用bash）
docker exec -it <imageID> ls -a <dir>  #显示所有文件
docker exec -it <imageID> cat <file>   #打印文件内容
docker exec -it <imageID> rails c        #进入rails c
docker exec -it <imageID> tail -f log/production.log  #查看rails日志（刷新页面看变化）
```

### 遇到的报错

1）***报错：rake aborted! LoadError: Error loading shared library liblzma.so，当执行 bundle exec 时***

解决办法：在 .env 中添加 `RAILS_ENV=production`，或执行 bundle exec 时加上 RAILS_ENV=production

2）***报错：bundle exec rails assets:precompile' returned a non-zero code，当执行 bundle exec 时***

解决办法：同上

3）***报错：OCI runtime create failed: container_linux.go:348: starting container process caused "exec: \"/registry\": executable file not found in $PATH": unknown，当执行 xxx exec 时***

这种报错比较难解决，因为从报错信息没有告诉我们到底缺少哪些文件，也不知道文件位置

原因：一般是执行的文件不存在，或环境变量所在文件不存在，或环境变量没有设置，或环境变量值错误（比如 POSTGRES_HOST 和 REDIS_HOST 必须对应到 docker-compose.yml 的 services 名）

解决办法：

- 检查 Dockerfile 所 FROM 的基础镜像（本项目所用基础镜像 FROM 于 ruby:alpine 所以没问题）。不要用空镜像 scratch，而是用一些稳定的自带常用包工具的镜像，比如 ubuntu、centos、debian，linux 各种包的 alpine 精简版，基于 glibc 生态的 busybox:glibc
- 检查所执行的文件是否存在
- 检查 .env 是否存在
- 在 .env 中添加如 `RAILS_ENV=production`

4）***报错：MessageEncryptor、MissingKeyError，这类跟 Encrypt 有关的***

原因有两种：

1）环境变量 RAILS_MASTER_KEY 错误。把 .env 的 RAILS_MASTER_KEY 改成和 config/master.key 一致

2）公钥私钥不匹配，或文件丢失。执行下面代码重新生成 config/credentials.yml.enc 和 config/master.key

```
rm config/master.key config/credentials.yml.enc  #确保重新生成
EDITOR=vim rails credentials:edit                       #重新生成
```

5）***报错：KeyError: Cannot load database configuration，数据库连接问题***

原因：一般是数据库变量加载不到或键值错误
