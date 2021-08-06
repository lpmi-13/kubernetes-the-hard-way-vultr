# this runs a local script on the remote controllers to bootstrap the control plane
for instance in controller-0 controller-1 controller-2; do
  external_ip=$(vultr-cli instance list | grep ${instance} \
    | awk -F ' ' '{print $2}')

  ssh -i kubernetes.id_rsa \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  root@$external_ip < ./scripts/bootstrap_control_plane.sh
done

echo "waiting 30 seconds for etcd to be fully initialized..."
sleep 30

for instance in controller-0; do
  external_ip=$(vultr-cli instance list | grep ${instance} \
    | awk -F ' ' '{print $2}')

  ssh -i kubernetes.id_rsa \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    root@$external_ip "kubectl get componentstatus"
done

echo "setting up RBAC from controller-0"

external_ip=$(vultr-cli instance list | grep controller-0 \
  | awk -F ' ' '{print $2}')

ssh -i kubernetes.id_rsa \
-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
root@$external_ip < ./scripts/set_up_rbac.sh

echo sleeping for three minutes to allow the backend to be ready to receive SSL connections...
sleep 180

KUBERNETES_PUBLIC_ADDRESS=$(vultr-cli load-balancer list | grep -i ipv4 | awk -F ' ' '{print $2}')

curl -k --cacert ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}/version

