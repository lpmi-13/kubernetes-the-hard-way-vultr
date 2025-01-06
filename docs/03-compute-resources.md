# Provisioning Compute Resources

to set the correct region in this shell, first run:

```
source scripts/set_env.sh
```

which should set your `$REGION` to `lhr`, but feel free to update the region in that file if you'd prefer a different one.

## Networking

### Private Network

> Vultr private networks are similar to VPCs on AWS, so we can use them to simplify the networking and isolate our kubernetes internal traffic.

```sh
NETWORK_ID=$(vultr-cli network create \
  --description "kubernetes-network" \
  --region-id "$REGION" \
  --subnet "10.240.0.0" \
  --size 24 \
| awk -F ' ' 'FNR == 2 {print $1}')
```

## Compute Instances

### SSH Key

create a local ssh key just for this exercise

```
ssh-keygen -t ed25519 -o -a 100 -f kubernetes.ed25519
```

> vultr wants the contents of the ssh key rather than a file reference, so we need to cat this out

```sh
AUTHORIZED_KEY=$(cat kubernetes.ed25519.pub | cut -d ' ' -f1-2)
```

now we can upload that key into the vultr system to be attached to our instances:

```sh
SSH_KEY_ID=$(vultr-cli ssh-key create \
  --name kubernetes-key \
  --key "$AUTHORIZED_KEY" \
  | awk -F ' ' 'FNR == 2 {print $1}')
```

### Kubernetes Controllers

> Using `vc2-1c-1gb` instances, slightly smaller than the t3.micro instances used in the AWS version, but should get the job done

```sh
for i in 0 1 2; do
  vultr-cli instance create \
    --host controller-${i} \
    --plan vc2-1c-1gb \
    --region ${REGION} \
    --ssh-keys ${SSH_KEY_ID} \
    --os 270 \
    --network ${NETWORK_ID} \
    --private-network "true" \
    --label controller-${i} \
    --tag controller
done
```

### Kubernetes Workers

```sh
for i in 0 1 2; do
  vultr-cli instance create \
    --host worker-${i} \
    --plan vc2-1c-1gb \
    --region ${REGION} \
    --ssh-keys ${SSH_KEY_ID} \
    --os 270 \
    --network ${NETWORK_ID} \
    --private-network "true" \
    --label worker-${i} \
    --tag worker
done
```

### Kubernetes Public Access - Create a Network Load Balancer

Now we need to iterate through the nodes and grab their instance IDs so we can attach them to the load balancer.

```sh
controller_0_id=$(vultr-cli instance list | grep controller-0 | awk -F ' ' '{print $1}')
controller_1_id=$(vultr-cli instance list | grep controller-1 | awk -F ' ' '{print $1}')
controller_2_id=$(vultr-cli instance list | grep controller-2 | awk -F ' ' '{print $1}')
```

and then use those IDs to associate the instances with the load balancer.

```sh
LOAD_BALANCER_ID=$(vultr-cli load-balancer create \
  --label "kubernetes-loadbalancer" \
  --instances ${controller_0_id},${controller_1_id},${controller_2_id} \
  --protocol tcp \
  --region ${REGION} \
  --private-network "$NETWORK_ID" \
  --forwarding-rules frontend_port:443,frontend_protocol:tcp,backend_port:6443,backend_protocol:tcp
  | awk -F ' ' 'FNR == 1 {print $2}')
```

> the load balancer will take a bit of time to be created, so if the ip address doesn't resolve with the following command, try again a bit later.

```sh
KUBERNETES_PUBLIC_ADDRESS=$(vultr-cli load-balancer get $LOAD_BALANCER_ID \
  | grep -i ipv4 | awk -F ' ' '{print $2}')
```

### Firewall

First we set up the firewall, then we add the rules to it.

```
FIREWALL_ID=$(vultr-cli firewall group create \
  --description "kubernetes-firewall" \
  | awk -F ' ' 'FNR == 2 {print $1}')

```

```sh
vultr-cli firewall rule create \
  --id "$FIREWALL_ID" \
  --notes "allow SSH" \
  --port "22" \
  --protocol "tcp" \
  --subnet "0.0.0.0" \
  --size 0 \
  --type "v4"
```

```sh
vultr-cli firewall rule create \
  --id "$FIREWALL_ID" \
  --notes "allow all pings" \
  --protocol "icmp" \
  --subnet "0.0.0.0" \
  --size 0 \
  --type "v4"
```

```sh
vultr-cli firewall rule create \
  --id "$FIREWALL_ID" \
  --notes "allow ingress from load balancer to k8s control plane" \
  --port "6443" \
  --protocol "tcp" \
  --subnet "0.0.0.0" \
  --size 0 \
  --type "v4"
```

```sh
vultr-cli firewall rule create \
  --id "$FIREWALL_ID" \
  --notes "allow communication between nodes via tcp" \
  --port 1:65535 \
  --protocol "tcp" \
  --subnet "10.240.0.0" \
  --size 16 \
  --type "v4"
```

```sh
vultr-cli firewall rule create \
  --id "$FIREWALL_ID" \
  --notes "allow communication between nodes via udp" \
  --port 1:65535 \
  --protocol udp \
  --subnet "10.240.0.0" \
  --size 16 \
  --type "v4"
```

```sh
vultr-cli firewall rule create \
  --id "$FIREWALL_ID" \
  --notes "allow communication between pods via tcp" \
  --port 1:65535 \
  --protocol "tcp" \
  --subnet "10.200.0.0" \
  --size 16 \
  --type "v4"
```

```sh
vultr-cli firewall rule create \
  --id "$FIREWALL_ID" \
  --notes "allow communication between pods via udp" \
  --port 1:65535 \
  --protocol "udp" \
  --subnet "10.200.0.0" \
  --size 16 \
  --type "v4"
```

after the firewall is all set up, we need a separate API call to add the controller instances to it.

```
for i in 0 1 2; do
  instance_id=$(vultr-cli instance list | grep controller-${i} | awk -F ' ' '{print $1}')
  vultr-cli instance update-firewall-group --firewall-group-id ${FIREWALL_ID} \
    --instance-id ${instance_id}
done
```

and we need to do the same for the worker instances

```
for i in 0 1 2; do
  instance_id=$(vultr-cli instance list | grep worker-${i} | awk -F ' ' '{print $1}')
  vultr-cli instance update-firewall-group --firewall-group-id ${FIREWALL_ID} \
    --instance-id ${instance_id}
done
```

And lastly, we need to do a bit of manual network routing configuration, since Vultr doesn't automatically configure
the network adapters for us. So we need to copy over the private network mappings and then set these up to receive
traffic via the `netplan` command:

```sh
for i in controller-0 controller-1 controller-2 worker-0 worker-1 worker-2; do
  public_ip=$(vultr-cli instance list | grep ${i} | awk -F ' ' '{print $2}')

  echo ssh -i kubernetes.ed25519 root@$public_ip
done
```

ssh into each of the instances (all 3 controllers and 3 worker), and run the following commands:

```sh
cat <<EOF | sudo tee /etc/netplan/06-enp6s0.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp6s0:
      dhcp4: no
      addresses: [PUT_THE_PRIVATE_IP_OF_INSTANCE_HERE/24]
EOF
```

and then a simple `netplan apply` should have your instance ready to receive traffic on the private network.

Next: [Certificate Authority](04-certificate-authority.md)
