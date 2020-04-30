## kubectl 命令行替代 dashboard

> [k8s 官网 - 启用 shell 自动补全功能](https://kubernetes.io/zh/docs/tasks/tools/install-kubectl/#%e9%85%8d%e7%bd%ae-kubectl)，所有 kubectl 命令都可以加 -h 查看参数选项

1）查看命名空间下的所有资源，对应不同命名空间下的 dashboard 主页面

查看更多信息在最后加 `-o wide`，all 可以替换成多个 api 简写，all 包括 pod,svc,deploy,rs,job，另外还有 pv,pvc,ns

```
kubectl get all,pv,pvc,ns -o wide

kubectl get all                                      #默认default命名空间
kubectl -n kubernetes-dashboard get all  #kubernetes-dashboard命名空间
kubectl get all -A                                 #所有命名空间
```

2）实时监控 pod 的状态

在 Makefile 自定义命令如 test，循环执行 kubectl get 监控如下，执行 `make test` 就能实现实时监控

```
test:
	# 自定义命令
	cat deployments/*.yaml | kubectl delete -f - --ignore-not-found
	cat deployments/*.yaml | kubectl apply -f -
	
	# 监控 pod 状态
	for i in {1..1000} ; do \
		sleep 3; kubectl get pod -o wide; echo ""; \
	done
```

3）查看日志。最常看的是 pod 的日志

```
kubectl logs -f <podName>                          #默认命名空间
kubectl -n <namespace> logs -f <podName>  #其他命名空间
```

4）进入容器以执行命令

基础镜像用哪种命令处理器就用哪个，比如 ruby 用 bash、ruby-alpine 用 sh。还可以把 sh 替换成常用 shell 命令如 `ls`。pod 为 rails 项目时可执行 `rails c`

```
kubectl exec -it <podName> sh             #进入容器（有的用bash）
kubectl exec -it <podName> ls -a <dir>  #显示所有文件
kubectl exec -it <podName> cat <file>   #打印文件内容
kubectl exec -it <podPuma> rails c        #进入rails c
kubectl exec -it <podPuma> tail -f log/production.log  #查看rails日志
```
