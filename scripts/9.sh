for instance in worker-0 worker-1 worker-2; do
  external_ip=$(vultr-cli instance list | grep ${instance} \
    | awk -F ' ' '{print $2}')

  ssh -i kubernetes.id_rsa \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  root@$external_ip < ./scripts/bootstrap_workers.sh
done

echo "waiting 60 seconds before checking worker status"
sleep 60

external_ip=$(vultr-cli instance list | grep controller-0 \
    | awk -F ' ' '{print $2}')

ssh -i kubernetes.id_rsa \
-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
root@$external_ip "kubectl get nodes --kubeconfig admin.kubeconfig"

