## Docker 安装

 [官网 docker 下载](https://www.docker.com/products/docker-desktop)，Community Edge 社区稳定版简称 CE

### docker 下载镜像慢

方法一（推荐）：**修改镜像源**

打开 docker 设置 -> Docker Engine

- 阿里云：[先登录](https://cr.console.aliyun.com/cn-hangzhou/instances/repositories) -> 左栏『镜像中心』-> 镜像加速器，复制加速器地址
- 微软：https://dockerhub.azk8s.cn

```
{
  "registry-mirrors": [
    "https://h75pzom3.mirror.aliyuncs.com",
    "https://dockerhub.azk8s.cn"
  ]
}
```

方法二：使用 sock5 代理

docker 设置 -> Resources -> Proxies 勾选 Manual proxy configuration，设置 http 和 https 为 `http://127.0.0.1:1087` （端口改为 sock5 代理端口）。最后执行 `docker info` 检查 Registry Mirrors 是否已修改

### docker 下载不了镜像

原因：镜像仓库 gcr.io 被墙导致，即使用 socks5 科学上网也下载不了

解决办法：在 [dockerhub](https://hub.docker.com/) 或 [阿里云容器镜像中心](https://cr.console.aliyun.com/cn-hangzhou/instances/images) 搜索相应镜像替换


## Kubernetes/k8s 安装

使用 [AliyunContainerService/k8s-for-docker-desktop 脚本安装](https://github.com/AliyunContainerService/k8s-for-docker-desktop)

1）修改 docker 镜像源为阿里云或微软

2）查看本地 k8s 版本：docker -> About Docker Desktop

3）克隆项目，编辑 images.properties 把所有 kube-xxx 的版本号改成本地 k8s 版本号

```
git clone https://github.com/AliyunContainerService/k8s-for-docker-desktop
```

4）执行脚本会开始安装 k8s

```
./load_images.sh   #Mac系统
.\load_images.ps1  #Windows系统
```

5）安装完成后，在 docker 设置里开启 k8s 并重启 docker

6）可能还会一直 starting，尝试：

- 可能成功：重置 Reset Kubernetes cluster，退出 docker，删除 ~/.kube 和  ~/Library/Group Containers/group.com.docker/pki，开启 docker 等待
- 可能成功：有可能是假死，其实已经安装好了，执行 `kubectl cluster-info`、`kubectl cluster-info dump`、`kubectl get nodes`，有数据返回说明已经安装成功
- [各种原因 Kubernetes is starting… state never ends](https://github.com/docker/for-mac/issues/2990)
- 未测试：[重置 /ets/hosts](https://github.com/docker/for-mac/issues/2985)
- 失败：`rm -rf ~/.kube`，备份镜像 ~/Library/Containers/com.docker.docker/Data，然后重置（设置 -> Reset to factory defaults），重装 docker 和 k8s
