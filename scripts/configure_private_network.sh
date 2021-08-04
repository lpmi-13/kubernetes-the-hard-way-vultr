NETPLAN_FILENAME="/etc/netplan/06-enp6s0.yaml"

HOST=$(hostname)

PRIVATE_IP_ADDRESS=$(grep ${HOST} private_network_mappings | awk -F ' ' '{print $2}')

cat <<EOF | sudo tee ${NETPLAN_FILENAME}
network:
  version: 2
  renderer: networkd
  ethernets:
    enp6s0:
      dhcp4: no
      addresses: [${PRIVATE_IP_ADDRESS}/24]
EOF

netplan apply
