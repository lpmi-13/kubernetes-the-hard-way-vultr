for instance in controller-0 controller-1 controller-2; do
  external_ip=$(vultr-cli instance list | grep ${instance} \
  | awk -F ' ' '{print $2}')

  ssh -i kubernetes.ed25519 \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    root@$external_ip < ./scripts/bootstrap_etcd_on_controllers.sh
done

