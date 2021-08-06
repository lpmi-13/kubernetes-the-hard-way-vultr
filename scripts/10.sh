KUBERNETES_PUBLIC_ADDRESS=$(vultr-cli load-balancer list | grep -i ipv4 \
  | awk -F ' ' '{print $2}')

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:443

kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem

kubectl config set-context kubernetes-the-hard-way \
  --cluster=kubernetes-the-hard-way \
  --user=admin

kubectl config use-context kubernetes-the-hard-way

echo these are the components with their status:
kubectl get componentstatuses

echo these are the nodes with their status:
kubectl get nodes

