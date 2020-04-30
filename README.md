# Deploying a Rails6 App to a Kubernetes Cluster

使用 docker-compose 和 k8s 开启常用服务：

- Rails 6，基于 ruby:2.7-alpine
- Postgresql 12.2，也支持 mysql、mariadb 数据库
- Redis 5
- Sidekiq 6

## 开始

包括五个部分

1）rails 项目：kube/文档/1-rails-demo.md

2）使用 docker-compose 开启所有服务

3）使用 k8s 开启所有服务

4）部署 k8s dashboard 仪表盘

5）kubectl 命令行代替 dashboard
