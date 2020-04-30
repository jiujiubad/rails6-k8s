# 1 天入门 Kubernetes/K8S

[【视频】1 天入门Kubernetes/K8S - 李振良 - 腾讯课堂](https://ke.qq.com/course/366778?taid=3842496786700474)

## K8S 架构

windows 工具 xshell6 可批量执行 vps

### 部署 k8s 的方法

- 二进制：目前企业用的最多。不用再编译和部署环境，一般都是针对平台如 x86。但要手动写配置参数，比较复杂
- kubeadm：目前企业用的第二多。是官方为简化部署而开发
- minikube：单机版，用于快速测试，不能用于生产环境
- yurn：非常方便，但用的人少

初学者推荐 kubeadm 因为二进制很容易从入门到放弃。入门了的推荐二进制部署，因为出现问题更好 debug


## 环境准备与安装kubeadm工具

### 使用 kubeadm 部署

> k8s 硬件软件要求：一台或多台 centos7，至少 2G RAM，生产环境至少双核 CPU（测试时单核也还行），禁用 swap 分区，能使用外网（用于拉取镜像）

1）所有 vps 创建节点

```
kubeadm init  #创建一个node节点
kubeadm join <master节点的ip和端口>  #把node节点加入到集群中
```

2）所有 vps 准备环境

```
#关闭防火墙
systemtl stop firewalld
systemtl disable firewalld

#关闭selinux
sed -i 's/enforcing/disables/' /etc/selinux/config
setenforce 0

#关闭swap
swapoff -a  #临时
vim /etc/fstab  #永久 

#添加主机名与ip的对应关系
$ vim /etc/hosts
192.168.0.1  master
192.168.0.1  node1
192.168.0.1  node2

#将桥接的ipv4流量传递到iptables链
$ cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system 
```

3）所有 vps安装 docker、kubeadm、kubelet、kubectl

使用阿里云 docker 镜像源，阿里云 yum 软件源

docker 可用 18.06，太新的版本可能兼容性不够好

## 部署 Master 与 Node 加入集群

## 部署 K8S Web UI

```
docker pull lizhenliang/kubernetes-dashboard-amd64:v1.10.1

wget https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl apply -f kubernetes-dashboard.yaml
kubectl delete -f kubernetes-dashboard.yaml
修改 image，由 `k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1` 改成 docker hub 的 `lizhenliang/kubernetes-dashboard-amd64:v1.10.1`
image
因为默认是只在集群内部能访问，要使用NodePort暴露端口（157 行 Dashboard Service，Kind: Service）在 spec 添加 type: NodePort，ports 添加 nodePort: 30001
kubectl apply -f kubernetes-dashboard.yaml
kubectl get pods -n kube-system  #UI默认放在kube-system命名空间下，看到状态是Running
用 https://ip:port 打开仪表盘
```

### 答疑

kubeadm 不建议使用它的证书，默认一年的有效期，你要修改证书有效期必须修改源码
k8s 监控系统用什么比较适合？目前主流普修罗米斯 prometheus operator（能兼容传统的架构和容器架构），或是 Grafana
数据库放在 pod 吗？mysql 感觉不太适合，大多数公司不会放这些有状态型的到 k8s 中，因为数据库是比较重量级的，而 k8s 更适合无状态的、弹性伸缩的、访问有波动的、代码快速版本迭代的，因为它能快速地部署或销毁，而数据库这种几年都不用重启一次服务器、几年都不用换一个架构的，它没必要，而且你放里面反倒增加维护的成本
ceph 是当下主流的存储吗？是，比如阿里云、腾讯云都用的非常多
新版本特性没讲到？版本东西不需要太多考虑，就像 python 一样，很多新版只是在修复功能


## 熟悉在 Kubernetes 部署应用的流程

制作镜像 -> 控制器管理 Pod -> 暴露应用 -> 对外发布应用 -> 监控

## 先在 Kubernetes 中部署一个 Java 应用

1）基础镜像（ubuntu），运行镜像（Ruby、Go），项目镜像

2）先本地创建数据库，并确保能用 host、user、password 连接上

编译项目

打包镜像 docker build，推送到仓库 docker push

创建 k8s 模板来修改（好处是不会出现从其他网站复制后的语法错误），删除不需要的字段如 creationTimestamp（时间戳）、strategy（升级策略）、status、resources（资源配置），relicas 副本数有几个 node 节点就用几个，image 默认在 dockerhub 拉取

```
docker search <username>  #搜索镜像
kubectl create -h  #-h查看参数
kubectl create deploytment java-demo --image=lizhenliang/java-demo --dry-run -o yaml > deploy.yaml  #其中--dry-run是测试模式不会实际执行，-o yaml输出为yaml
kubectl apply -f deploy.yaml
kubectl get pods
kubectl logs <pod_name>
```

3）创建 service 模板

其中 --port 是 service 的端口，用于集群内部访问。--target-port 是容器里面跑服务的端口。--type 指定类型为 NodePort，会随机生成一个端口，生成的端口用于集群外部用户访问

```
kubectl expose deployment java-demo --port=80 --target-port=8080 --type=NodePort --dry-run -o yaml > svc.yaml
kubectl apply -f svc.yaml
kubectl get pods,svc
```

通过 host:port 就能访问，项目已成功部署！如果数据库连接有问题，这时在网页上的操作是连接不上的

## Pod 存在的意义

以下场景适合把容器放在同个 Pod（设置亲和性）

- 数据共享，比如两个应用之间发生文件交互通过 volume
  - 临时数据
  - 日志
  - 业务数据
- 网络共享，比如两个应用需通过 127.0.0.1 或 socket 通信
- 网络共享，比如两个应用频繁发生调用，设置后性能会大幅度提升

## Pod 实现机制

可以导出一个做测试，删掉大部分用不上的字段

```
kubectl get pods java-demo-xxx -o yaml > pod.yaml

apiVersion: v1
kind: Pod
metadata:
  lavels: 
    app: my-pod
  name: my-pod
  namespace: default
spec:
  containers:
  - image: nginx
     name: nginx
     image: nginx
  - image: java-demo
     name: java
     image: linzhenliang/java-demo:lastest

kubectl get pod  #会看到READY是两个即2/2
kubectl exec -it my-pod -c java bash  #因为有两个pod，用-c指定容器名
ifconfig  #查看分配的ip
cat /etc/issue  #查看使用的系统（ubuntu/centos等）
apt-get update
```

**Pod 网络共享的实现**：查看分配的 ip，会发现 nginx 和 java-demo 的 ip是一样的，因为 pod 默认会创建基础容器 infra（执行 `docker ps` 会看到很多带 pause 字眼的容器），infra 创建了 ip、port、mac 等网络信息，后面创建的容器 nginx 和 java-demo 等都会加入到 infra

**Pod 文件共享的实现**：volume

## Pod 分类与 Pod Template 常见字段

Infrastructure Container 基础容器，Init Container 初始化容器，Containers 业务容器

在 deployment.yaml 文件中，上面的部分是容器 Container

- name 控制器名
- namespace 命名空间
- replicas 副本数
- selector 标签选择器，当与 pod 即 template 下的标签对应时才匹配

下面 template 的部分是 pod 模板：

- 首先定义标签（用于控制器与 pod 关联）
- 再拉取镜像（涉及到私有仓库认证）
- container 业务容器部分定义多个容器（用 name 分开）
  - `imagePullPolicy: Always` 表示只要本地有就不再拉取镜像，也就是不会拉取最新镜像 
  - port 所连接的应用的端口
  - env 传入变量
  - resources 默认可以使用 node 的所有 cpu 和内存，如果出现内存泄露会导致其他容器出问题，最后当前节点可能会与集群脱离
  - 健康检查
    - readinessProbe：如果 pod 不正常会一直尝试重建
    - livenessProbe：如果 pod 不正常，就不会为它转发流量

## Deployment 控制器及应用场景

controller 控制器又叫 workload

控制器通过标签 label 管理 pod，使用控制器去部署应用，然后通过标签去关联 pod

deployment 用于部署无状态应用，管理 pod 和 replicaSet，可设置副本数，滚动更新，回滚。应用场景是部署 Web 服务、部署微服务

## 使用 Deployment 部署 Java 应用

标签最好至少定义两个，一个是项目名，一个是项目下的 app 名字

`ps -ef | grep mariadb`

发布

## 应用升级、回滚、弹性伸缩

1. 项目升级（滚动更新），无非就是升级镜像。如果没有做健康检查升级会非常快

```
kubectl set image -h
kubectl set image <deployment/web> <java=nginx>  #升级方式1
kubectl edit <svc/web>                                        #升级方式2：直接编辑 yaml 进行更新
kubectl rollout status <deployment/nginx>               #查看升级状态
```

2. 项目回滚

```
kubectl rollout history <deployment web>  #查看历史记录
kubectl rollout undo <deployment web>     #回滚到上个版本
```

3. 扩容更多服务器

场景：双十一淘宝扩容服务器，应对当天的高并发

```
kubectl scale -h
kubectl scale -h <deployment web> --replicas=5
```

4. deployment（简称 deploy）、replicaset（简称 rs）、pod 的关系

创建 deployment 后会先创建 replicaset（rs）

- rs 管理 pod 的数量保持与副本数 replicas 一致
- rs 记录历史版本。滚动更新的步骤是先创建一个新的 rs 跑新的副本，准备就绪后杀掉旧 rs 里的一个副本，直到旧副本数为 0

## Service 存在的意义

意义在于

- 关联一个应用
- 找到一组 pod 和对应的 ip 以防止 pod 失联。比如前段三个 pod 一组，后端三个 pod 一组
- 定义一组 pod 负载均衡
- 暴露端口，方式有 service（对应四种 ip 即集群内部 ClusterIP、nodeport 节点 ip、LoadBalancer 云服务商 ip、ExternalName 通过 DNS CNAME 转发到指定域名）、ingress

## Service 三种类型

nodeport 有多个时类似于有多个 web，共用一个 LB（loadBalancer），用户通过访问这个标签就能连接到应用。缺点是每添加一个节点，都有相应添加一个 LB，需要增加一定的工作量

LoadBalancer 会在 nodeport 的基础上自动添加共用 LB。缺点是仅限于一些公有云，比如 aws、微软云、阿里云

## Service NodePort 对外暴露你的应用

- service 默认通过 iptable 工具（屏蔽/放行/转发 ip）实现负载均衡。当创建很多 service 时，iptable 的性能会大大下降，因为 iptable 管理的是一张表每次查找都会全表匹配
- IPVS（建议生产环境使用） 用于替代 iptable，不会存在性能问题，而且支持多种调度算法（rr、wrr、lc、wlc 等）

LVS 是一个成熟的负载均衡器，比如阿里云、腾讯云的 SLB 四层都是基于 LVS

service，是通过 kube-proxy 实现的

## Ingress 为弥补 NodePort 的不足而生

nodeport 的问题：

- 端口冲突。需要记录端口以保证不冲突
- nodeport 的 TCP/UDP 是四层的，不能做七层的事（比如工具域名转发）
- 不能为集群所有的 pod 做统一的转发、统一的入口（只要访问入口就能根据域名找到对应的 pod 上）

ingress 不是负载均衡，它是一个规则，为你创建 pod 的转化策略

ingress 通过 service 关联 pod，基于域名访问，通过 Ingress Controller 实现 pod 的负载均衡，支持 TCP/UDP 四层和七层

Ingress Controller 实现负载均衡要通过其他控制器如 nginx（通过 upstream 按照 ingress 的规则代理一组 pod）。ingress 创建好规则后，控制器发现有新应用部署时会新建一个 upstream，并做 proxy pass 代理实现负载均衡

## Ingress 对外暴露你的应用

1）首先要部署 Ingress Controller

官方 ingress-controller.yaml nginx 版本代码：

- kind: Namespace 指定命名空间
- kind: Configmap 配置文件，包括 tcp、udp 的，这两个就能配置四层的负载均衡，但我们主要还是用七层的
- kind: ServiceAccount 动态获取 ingress 规则
- kind: ClusterRole 访问 master 的授权 RBAC，因为不是每个人都能访问 master 的
- kind: Role 角色
- kind: RoleBinding 权限集合
- kind: ClusterRoleBinding 角色绑定，绑定到指定账户上
- kind: DaemonSet 部署 ingress 的镜像。**DaemonSet 对比 Deployment 的特性是，在每个 node 上都起一个同样的 pod，不多不少就起一个**。适用于要在 node 上跑一个守护进程的程序，比如日志采集、监控。
  - 其中 hostNetwork 是使用宿主机的网络（建议使用），这样性能会更好，如果使用 nodeport 去暴露 ingress 也可以，但性能没有 hostNetwork 好
  - serviceAccountName 访问 api server 的账号
  - image 镜像如 lizhenliang/nginx-ingress-controller:0.20.0 方便下载
  - args 启动应用程序所需配置，包括名字、cofigmap 参数、tcp 四层转发、udp 四层转发、publish-service 暴露的 service、perfix 前缀即可以部署多个 ingress controller
  - securityContext 容器相关变量、权限
  - port 暴露端口
  - livenessProbe、readinessProbe 健康检查
- kind: Service 创建 service 只是为了让 service 能找到它自己，不创建也能用

执行

```
kubectl apply -f ingress-controller.yaml
kubectl get pods -n ingress-nginx
```

如果节点多的话，你完全没必要在每个 node 上都跑一个 ingress controller，你可以找一批机器做负载均衡去跑 ingress controller

2）其次创建 ingress 规则表示为哪些应用做负载均衡

必须为应用指定：

- 域名 host，因为是基于域名做分流的
- serviceName 应用关联的 service 是谁
- sevicePort 应用端口

域名解析到部署 ingress controller 的机器的 ip 上，然后 `ping <域名>` 看有没有解析成功

## Ingress Nginx 工作原理

1. 使用 `kubectl apply -f ingress-controller.yaml`，就会提交到 master
2. nginx 控制器从 master 拿到 host、service、port
3. nginx 为用当前的 ingress 创建 upstream（要写 server/id，server/ip，所关联的 ip 和端口可通过 `kubectl get ep` 查看），然后通过 proxy pass 转发服务
4. 用户输入域名时，请求 80 端口也就是 nginx。nginx 根据 serverName 帮你转发到不同的 upstream 里，然后传到不同的 pod
