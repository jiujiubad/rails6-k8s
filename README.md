# Deploying a Rails6 App to a Kubernetes Cluster

分别使用 docker-compose 和 k8s 部署常用服务：

- Rails 6，基于 ruby:2.7-alpine 镜像
- Postgresql 12.2，也支持使用 mysql、mariadb 数据库
- Redis 5
- Sidekiq 6

## 开始

包括五个部分

1）rails 项目：[kube/文档/1-rails-demo.md](https://github.com/jiujiubad/rails6-k8s/blob/master/kube/%E6%96%87%E6%A1%A3/1-rails-demo.md)

2）使用 docker-compose 部署所有服务：[kube/文档/2-docker-compose.md](https://github.com/jiujiubad/rails6-k8s/blob/master/kube/%E6%96%87%E6%A1%A3/2-docker-compose.md)

3）使用 k8s 部署所有服务：[kube/文档/3-k8s.md](https://github.com/jiujiubad/rails6-k8s/blob/master/kube/%E6%96%87%E6%A1%A3/3-k8s.md)

4）部署 k8s dashboard 仪表盘：[kube/文档/4-k8s-dashboard.md](https://github.com/jiujiubad/rails6-k8s/blob/master/kube/%E6%96%87%E6%A1%A3/4-k8s-dashboard.md)

5）kubectl 命令行代替 dashboard：[kube/文档/5-k8s-命令行替代dashboard.md](https://github.com/jiujiubad/rails6-k8s/blob/master/kube/%E6%96%87%E6%A1%A3/5-k8s-%E5%91%BD%E4%BB%A4%E8%A1%8C%E6%9B%BF%E4%BB%A3dashboard.md)

## 学习资料

- [【视频】1 天入门Kubernetes/K8S - 李振良 - 腾讯课堂](https://ke.qq.com/course/366778?taid=3842496786700474)
- [【精】kuboard 中文文档 - 翻译 k8s 官网文档](https://kuboard.cn/learning/)
