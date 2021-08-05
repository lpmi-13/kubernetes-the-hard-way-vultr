# About

Following along after the smashing success of both k8s the hard way digitalocean and k8s the hard way linode...here's the same thing, but on Vultr!

This is a fork of the outstanding [Kubernetes The Hard Way - AWS](https://github.com/prabhatsharma/kubernetes-the-hard-way-aws), itself a fork of the awesome [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) by Kelsey Hightower and is geared towards using it on Vultr.

1. Kubernetes v1.17.2
2. cri-tools v1.17.0
3. containerd v1.3.2
4. CNI plugins v0.8.5
5. etcd v3.3.18
6. doctl v1.60.0

# Kubernetes The Hard Way

This tutorial walks you through setting up Kubernetes the hard way. This guide is not for people looking for a fully automated command to bring up a Kubernetes cluster. If that's you then check out [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine), [AWS Elastic Container Service for Kubernetes](https://aws.amazon.com/eks/) or the [Getting Started Guides](http://kubernetes.io/docs/getting-started-guides/).

Kubernetes The Hard Way is optimized for learning, which means taking the long route to ensure you understand each task required to bootstrap a Kubernetes cluster.

> The results of this tutorial should not be viewed as production ready, and may receive limited support from the community, but don't let that stop you from learning!

## Target Audience

The target audience for this tutorial is someone planning to support a production Kubernetes cluster and wants to understand how everything fits together.

## Cluster Details

Kubernetes The Hard Way guides you through bootstrapping a highly available Kubernetes cluster with end-to-end encryption between components and RBAC authentication.

* [Kubernetes](https://github.com/kubernetes/kubernetes) 1.17.2
* [containerd Container Runtime](https://github.com/containerd/containerd) 1.3.2
* [gVisor](https://github.com/google/gvisor) 08879266fef3a67fac1a77f1ea133c3ac75759dd
* [CNI Container Networking](https://github.com/containernetworking/cni) 0.8.5
* [etcd](https://github.com/coreos/etcd) 3.3.18

## Labs

This tutorial assumes you have access to [Vultr](https://www.vultr.com/). If you are looking for the GCP version of this guide then look at : [https://github.com/kelseyhightower/kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way).

* [Prerequisites](docs/01-prerequisites.md)
* [Installing the Client Tools](docs/02-client-tools.md)
* [Provisioning Compute Resources](docs/03-compute-resources.md) (WIP)
* [Provisioning the CA and Generating TLS Certificates](docs/04-certificate-authority.md)
* [Generating Kubernetes Configuration Files for Authentication](docs/05-kubernetes-configuration-files.md)
* [Generating the Data Encryption Config and Key](docs/06-data-encryption-keys.md)
* [Bootstrapping the etcd Cluster](docs/07-bootstrapping-etcd.md)
* [Bootstrapping the Kubernetes Control Plane](docs/08-bootstrapping-kubernetes-controllers.md)
* [Bootstrapping the Kubernetes Worker Nodes](docs/09-bootstrapping-kubernetes-workers.md) (WIP)
* [Configuring kubectl for Remote Access](docs/10-configuring-kubectl.md) (WIP)
* [Provisioning Pod Network Routes](docs/11-pod-network-routes.md) (WIP)
* [Deploying the DNS Cluster Add-on](docs/12-dns-addon.md) (WIP)
* [Smoke Test](docs/13-smoke-test.md) (WIP)
* [Cleaning Up](docs/14-cleanup.md) (WIP)
## Scripts

Since I'm only able to work on this in short stretches, it's easiest to script out steps so I can pick up where I left off. If you'd like to get to a certain point automatically, for example, the end of the steps in `docs/06-data-encryption-keys.md`, then you can run:

```
for i in {3..6}; do
    ./scripts/${i}.sh
done
```

And to clean up at any point, just run `./scripts/14.sh`. This also removes all the local resources (like yaml config files and ssh keys) that were generated along the way.
