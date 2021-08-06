# Deploying the DNS Cluster Add-on

In this lab you will deploy the [DNS add-on](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) which provides DNS based service discovery to applications running inside the Kubernetes cluster.

## The DNS Cluster Add-on

Deploy the `kube-dns` cluster add-on:

```
kubectl create -f https://raw.githubusercontent.com/lpmi-13/kubernetes-the-hard-way-vultr/main/deployments/core-dns.yaml
```

> output

```
serviceaccount/coredns created
clusterrole.rbac.authorization.k8s.io/system:coredns created
clusterrolebinding.rbac.authorization.k8s.io/system:coredns created
configmap/coredns created
deployment.apps/coredns created
service/kube-dns created
```

List the pods created by the `kube-dns` deployment:

```
kubectl get pods -l k8s-app=kube-dns -n kube-system
```

> output

```
NAME                       READY     STATUS    RESTARTS   AGE
coredns-7cb4c7458d-p7hxn   1/1       Running   0          20s
```

## Verification

Create a `dnsutils` pod

```
kubectl run busybox --image=busybox:1.28.4 --restart=Never -- sleep 3600
```

Verify that the pod is running:

```sh
kubectl get pod busybox
```

Output:
```
NAME       READY     STATUS    RESTARTS   AGE
busybox   1/1       Running   0          45s
```

Execute a DNS lookup for the `kubernetes` service inside the `dnsutils` pod:

```
kubectl exec -it busybox -- nslookup kubernetes
```

> output

```
Server:    10.32.0.10
Address 1: 10.32.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.32.0.1 kubernetes.default.svc.cluster.local
```

Next: [Smoke Test](13-smoke-test.md)
