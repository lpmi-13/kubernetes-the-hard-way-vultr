source scripts/set_env.sh

NETWORK_ID=$(vultr-cli network create \
  --description "kubernetes-network" \
  --region-id "$REGION" \
  --subnet "10.240.0.0" \
  --size 24 \
| awk -F ' ' 'FNR == 2 {print $1}')

ssh-keygen -t rsa -b 4096 -f kubernetes.id_rsa -N ""

AUTHORIZED_KEY=$(cat kubernetes.id_rsa.pub | cut -d ' ' -f1-2)

SSH_KEY_ID=$(vultr-cli ssh-key create \
  --name kubernetes-key \
  --key "$AUTHORIZED_KEY" \
  | awk -F ' ' 'FNR == 2 {print $1}')


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


controller_0_id=$(vultr-cli instance list | grep controller-0 | awk -F ' ' '{print $1}')
controller_1_id=$(vultr-cli instance list | grep controller-1 | awk -F ' ' '{print $1}')
controller_2_id=$(vultr-cli instance list | grep controller-2 | awk -F ' ' '{print $1}')

LOAD_BALANCER_ID=$(vultr-cli load-balancer create \
  --label "kubernetes-loadbalancer" \
  --instances ${controller_0_id},${controller_1_id},${controller_2_id} \
  --protocol "tcp" \
  --port "6443" \
  --check-interval "10" \
  --response-timeout "5" \
  --unhealthy-threshold "3" \
  --region ${REGION} \
  --private-network "$NETWORK_ID" \
  --forwarding-rules frontend_port:443,frontend_protocol:tcp,backend_port:6443,backend_protocol:tcp \
  | awk -F ' ' 'FNR == 1 {print $2}')

echo load balancer ID: $LOAD_BALANCER_ID

while [ "$LOAD_BALANCER_ID" == "creating" ];
do
  echo "waiting for load balancer to start"
  sleep 10
  LOAD_BALANCER_ID=$(vultr-cli load-balancer list | awk 'FNR == 1 {print $2}')
done

KUBERNETES_PUBLIC_ADDRESS=$(vultr-cli load-balancer get ${LOAD_BALANCER_ID} \
  | grep -i ipv4 | awk -F ' ' '{print $2}')


FIREWALL_ID=$(vultr-cli firewall group create \
  --description "kubernetes-firewall" \
  | awk -F ' ' 'FNR == 2 {print $1}')


vultr-cli firewall rule create \
  --id "$FIREWALL_ID" \
  --notes "allow SSH" \
  --port "22" \
  --protocol "tcp" \
  --subnet "0.0.0.0" \
  --size 0 \
  --type "v4"

vultr-cli firewall rule create \
  --id "$FIREWALL_ID" \
  --notes "allow all pings" \
  --protocol "icmp" \
  --subnet "0.0.0.0" \
  --size 0 \
  --type "v4"

vultr-cli firewall rule create \
  --id "$FIREWALL_ID" \
  --notes "allow ingress from load balancer to k8s control plane" \
  --port "6443" \
  --protocol "tcp" \
  --subnet "0.0.0.0" \
  --size 0 \
  --type "v4"

vultr-cli firewall rule create \
  --id "$FIREWALL_ID" \
  --notes "allow communication between nodes via tcp" \
  --port 1:65535 \
  --protocol "tcp" \
  --subnet "10.240.0.0" \
  --size 16 \
  --type "v4"

vultr-cli firewall rule create \
  --id "$FIREWALL_ID" \
  --notes "allow communication between nodes via udp" \
  --port 1:65535 \
  --protocol udp \
  --subnet "10.240.0.0" \
  --size 16 \
  --type "v4"

vultr-cli firewall rule create \
  --id "$FIREWALL_ID" \
  --notes "allow communication between pods via tcp" \
  --port 1:65535 \
  --protocol "tcp" \
  --subnet "10.200.0.0" \
  --size 16 \
  --type "v4"

vultr-cli firewall rule create \
  --id "$FIREWALL_ID" \
  --notes "allow communication between pods via udp" \
  --port 1:65535 \
  --protocol "udp" \
  --subnet "10.200.0.0" \
  --size 16 \
  --type "v4"

# apparently the firewall takes a while to be ready for "subscriptions", so we put in a sleep here

echo sleeping for 20 seconds to allow the firewall to be ready to take subscriptions
sleep 20

for i in 0 1 2; do
  controller_instance_id=$(vultr-cli instance list | grep controller-${i} | awk -F ' ' '{print $1}')
  vultr-cli instance update-firewall-group --firewall-group-id ${FIREWALL_ID} \
    --instance-id ${controller_instance_id}
  worker_instance_id=$(vultr-cli instance list | grep worker-${i} | awk -F ' ' '{print $1}')
  vultr-cli instance update-firewall-group --firewall-group-id ${FIREWALL_ID} \
    --instance-id ${worker_instance_id}
done

for i in 0 1 2; do
  controller_public_ip=$(vultr-cli instance list | grep controller-${i} | awk -F ' ' '{print $2}')

  scp -i kubernetes.id_rsa \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  private_network_mappings root@${controller_public_ip}:~/

  ssh -i kubernetes.id_rsa \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  root@$controller_public_ip < ./scripts/configure_private_network.sh

  worker_public_ip=$(vultr-cli instance list | grep worker-${i} | awk -F ' ' '{print $2}')

  scp -i kubernetes.id_rsa \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  private_network_mappings root@${worker_public_ip}:~/

  ssh -i kubernetes.id_rsa \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  root@$worker_public_ip < ./scripts/configure_private_network.sh
done

