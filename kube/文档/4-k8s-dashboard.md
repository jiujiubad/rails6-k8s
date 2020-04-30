## 部署 k8s dashboard 仪表盘

> dashboard 不是必须品，熟练了用 kubectl 更好。部署 dashboard 的坑很多，如果部署失败了就先跳过

[教程-成功：Centos7 安装 k8s 集群 1.15.0 及 kubernetes dashboard](https://juejin.im/post/5d089f49f265da1baa1e7611)

### 下载配置文件

最新文件见 [kubernetes/dashboard](https://github.com/kubernetes/dashboard) 描述区

```
wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
```

如果 wget 报错，是因为 raw.githubusercontent.com 被墙。解决办法是用 [ipaddress 查询真实ip](https://www.ipaddress.com/)，然后 `sudo vim /etc/hosts`，添加如 `199.232.68.133 raw.githubusercontent.com`

### 下载镜像

在 yaml 文件上搜索 image，如果带有 gcr.io 会被墙，要在 [dockerhub](https://hub.docker.com/) 或 [阿里云容器镜像中心](https://cr.console.aliyun.com/cn-hangzhou/instances/images) 搜索相应镜像替换

v2.0.0 用到的镜像没有被墙，直接下载：

```
docker pull kubernetesui/metrics-scraper:v1.0.4
docker pull kubernetesui/dashboard:v2.0.0
```

### 集群暴露外部端口

搜索 `kind: Service`，找到 labels 为 `k8s-app: kubernetes-dashboard` 的位置，添加 `type: NodePort` 和 `nodePort: 30001`

```
type: NodePort
ports:
	- port: 443
		targetPort: 8443
		nodePort: 30001
```

然后，开启 kubernetes-dashboard 和 dashboard-metrics-scraper 服务

```
kubectl apply -f recommended.yaml
kubectl delete -f recommended.yaml  #如需删除
```

查看 pod 的状态，逐渐变为 Running 为正常，否则查看 pod 的日志。另外，可以看到 service 的 type 变为 NodePort，PORT 为 443:30001

```
kubectl -n kubernetes-dashboard get all
kubectl -n kubernetes-dashboard logs -f <pod_name>
```

### 在浏览器打开

**使用 Firefox 浏览器**打开 <https://localhost:30001>，**不要用 chrome 和 safari** 会报错。登录界面选择 Token，获取如下

```
echo $(kubectl -n kube-system describe secret default| awk '$1=="token:"{print $2}')
```

修改语言：dashboard 会根据浏览器语言设置为自己的界面语言，修改浏览器语言后重启浏览器
