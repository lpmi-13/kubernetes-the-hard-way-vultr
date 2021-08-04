INSTANCES_TEST=$(vultr-cli instance list | awk 'FNR == 2 {print $1}')
# this is crap, but the cli doesn't support returning json yet
if [ "$INSTANCES_TEST" == "======================================" ]; then
  echo "no instances found"
else
  for instance_id in $(vultr-cli instance list | awk 'FNR > 1 {print $1}' | head -n 6); do
    echo "deleting instance: ${instance_id}"
    vultr-cli instance delete ${instance_id}
  done
fi

SSH_KEY_ID=$(vultr-cli ssh-key list | awk 'FNR == 2 {print $1}')
if [ ${SSH_KEY_ID} == "======================================" ]; then
  echo "no ssh key found"
else
  echo "deleting key with ID: ${SSH_KEY_ID}"
  vultr-cli ssh-key delete ${SSH_KEY_ID}
fi

LOCAL_PRIVATE_SSH_KEY="kubernetes.id_rsa"
if [ -f "$LOCAL_PRIVATE_SSH_KEY" ]; then
  echo "deleting local private ssh key previously generated"
  rm -rf kubernetes.id_rsa
else
  echo "no local private key found"
fi

LOCAL_PUBLIC_SSH_KEY="kubernetes.id_rsa.pub"
if [ -f "$LOCAL_PUBLIC_SSH_KEY" ]; then
  echo "deleting local public ssh key previously generated"
  rm -rf kubernetes.id_rsa.pub
else
  echo "no local public key found"
fi

LOAD_BALANCER_ID=$(vultr-cli load-balancer list | awk -F ' ' 'FNR == 1 {print $2}')
if [ -z ${LOAD_BALANCER_ID} ]; then
  echo "no load balancer found"
else
  echo "deleting load balancer: ${LOAD_BALANCER_ID}"
  vultr-cli load-balancer delete ${LOAD_BALANCER_ID}
fi

# sometimes it takes the load balancer a few seconds to disappear, so we can sleep a bit here
sleep 10

FIREWALL_ID=$(vultr-cli firewall group list | awk 'FNR == 2 {print $1}')
if [ ${FIREWALL_ID} == "======================================" ]; then
  echo "no firewall found"
else
  echo "deleting firewall: ${FIREWALL_ID}"
  vultr-cli firewall group delete ${FIREWALL_ID}
fi

NETWORK_ID=$(vultr-cli network list | awk 'FNR == 2 {print $1}')
if [ ${NETWORK_ID} == "======================================" ]; then
  echo "no private network found"
else
  echo "sleeping for 10 seconds to allow instances to be deleted first"
  sleep 10
  echo "deleting Network: ${NETWORK_ID}"
  vultr-cli network delete ${NETWORK_ID}
fi

echo "cleaning up local *.{csr,json,kubeconfig,pem,yaml} files"
rm -rf ./*.{csr,json,kubeconfig,pem,yaml}
