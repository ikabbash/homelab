#!/bin/bash

set -e

cat << 'EOF'
+---------------------------------------------------------+
| _  _____           ___           _        _ _           |
|| |/ ( _ ) ___     |_ _|_ __  ___| |_ __ _| | | ___ _ __ |
|| ' // _ \/ __|     | || '_ \/ __| __/ _` | | |/ _ \ '__||
|| . \ (_) \__ \     | || | | \__ \ || (_| | | |  __/ |   |
||_|\_\___/|___/    |___|_| |_|___/\__\__,_|_|_|\___|_|   |
+---------------------------------------------------------+
EOF

# Get the latest tag of any Github repo
get_latest_release () {
  local repo_path=$1
  git ls-remote --tags https://github.com/"${repo_path}".git | awk -F'/' '{print $NF}' | grep -v '{}' | grep -E '^[vV]?[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1
}

# Helper function in case there are keys that aren't already present
set_yaml_var () {
  local key=$1
  local value=$2
  local file=$3
  if grep -qE "^${key}:" "${file}"; then
    sed -i "s/^${key}:.*/${key}: ${value}/" "${file}"
  else
    echo "${key}: ${value}" >> "${file}"
  fi
}

# Set/replace a multi-line YAML block scalar ("key: |" followed by indented lines).
# Removes any previous block for this key first, so reruns don't pile up duplicates.
set_yaml_block () {
  local key=$1
  local value=$2
  local file=$3
  awk -v k="^${key}: \\\\|\$" '
    $0 ~ k { skip=1; next }
    skip && /^[[:space:]]/ { next }
    { skip=0; print }
  ' "${file}" > "${file}.tmp" && mv "${file}.tmp" "${file}"
  {
    echo "${key}: |"
    printf '%s\n' "${value}" | sed 's/^/  /'
  } >> "${file}"
}

# Define colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

BASE_DIR=$(readlink -f $(dirname ${0}))
SSH_PORT="22"
KUBESPRAY_SRC_DIR="/usr/local/src/kubespray"
KUBESPRAY_INV_DIR="${KUBESPRAY_SRC_DIR}/inventory/mycluster"
KUBESPRAY_INV_FILE="${KUBESPRAY_INV_DIR}/hosts.ini"
ETCD_CONFIG_FILE="${KUBESPRAY_INV_DIR}/group_vars/all/etcd.yml"
CLUSTER_CONFIG_FILE="${KUBESPRAY_INV_DIR}/group_vars/k8s_cluster/k8s-cluster.yml"
ETCD_MODE="host" # Either host or kubeadm (static pod)

# Configs
CLUSTER_NODES_IPS=(192.168.100.33) # CHANGE THIS
AUTO_RENEW_CERTIFICATES="true" # kubeadm cert auto-renewal via systemd timer
KUBELET_IMAGE_MAXIMUM_GC_AGE="720h" # kubelet arg, leave empty ("") to skip
# Pod Security Admission default applied to every namespace at every level (enforce/audit/warn), leave empty ("") to skip
PSA_DEFAULT_LEVEL="restricted"
# Namespaces to be exempted from the PSA (kube-system is always exempted); e.g. (cert-manager ingress-nginx)
PSA_EXEMPT_NAMESPACES=(monitoring openebs)

ENABLE_AUDIT="true"
AUDIT_POLICY_FILE="${BASE_DIR}/audit-policy.yaml"
AUDIT_LOG_MAXAGE="30"
AUDIT_LOG_MAXBACKUPS="10"
AUDIT_LOG_MAXSIZE="100"

PYTHON_ENV_DIR="${KUBESPRAY_SRC_DIR}/python-venv"

# Step 1: Enable passwordless sudo and ensure connection on target servers with same username (a prompt for password might appear)
init_connections () {
  # Execute using the default user and make sure all app servers use the same default user
  if [ $(echo ${EUID}) = 0 ]; then
    echo -e "${RED}${BOLD}Current user is root, please change the user to the default user to proceed${RESET}"
    exit 1
  fi
  echo -e "${BLUE}Your user is ${USER}, make sure that all servers have the same user with the same password${RESET}"
  # Check connectivity between servers using netcat
  for CLUSTER_NODE_IP in ${CLUSTER_NODES_IPS[@]}; do
    nc -z -v ${CLUSTER_NODE_IP} ${SSH_PORT} > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo -e "${BLUE}Deployment server can ssh to ${CLUSTER_NODE_IP}${RESET}"
    else
      echo -e "${RED}${BOLD}Deployment server can't ssh to ${CLUSTER_NODE_IP}, please check connectivity and proper IP assignemnt${RESET}"
      exit 1
    fi
  done
  # Generate ssh keys on main server
  if [ ! -f ~/.ssh/admin-k8s ]; then
    ssh-keygen -q -t ed25519 -C "admin-k8s" -f ~/.ssh/admin-k8s -N ""
    cat ~/.ssh/admin-k8s.pub >> ~/.ssh/authorized_keys
  fi
  eval $(ssh-agent -s)
  ssh-add ~/.ssh/admin-k8s
  for CLUSTER_NODE_IP in ${CLUSTER_NODES_IPS[@]}
  do
    ssh-keyscan -H "${CLUSTER_NODE_IP}" >> ~/.ssh/known_hosts
    # Enable passwordless sudo on servers
    ssh -t ${USER}@${CLUSTER_NODE_IP} "if sudo cat /etc/sudoers | grep -q "NOPASSWD"; then \
    echo "user ${USER} has passwordless sudo privilges on the server with IP ${CLUSTER_NODE_IP}"; else \
    echo '%sudo  ALL=(ALL) NOPASSWD:ALL' | sudo EDITOR='tee -a' visudo; fi"
    ssh-keyscan -H ${CLUSTER_NODE_IP} >> /home/${USER}/.ssh/known_hosts
    ssh-copy-id -i ~/.ssh/admin-k8s ${CLUSTER_NODE_IP}
  done
}

# Step 2: Install dependencies all servers and disable swap
download_dependencies () {
  # Check https://discuss.kubernetes.io/t/swap-off-why-is-it-necessary/6879 if you're not sure why
  for CLUSTER_NODE_IP in ${CLUSTER_NODES_IPS[@]}; do
    ssh -t ${USER}@${CLUSTER_NODE_IP} "sudo apt-get update && \
    sudo apt-get upgrade -y && \
    sudo apt-get install git python3 net-tools python3-pip python3-venv iputils-ping -y && \
    sudo swapoff -a && \
    if grep -qE '^[^#].*[[:space:]]swap[[:space:]]' /etc/fstab; then \
      sudo sed -i.bak -E '/^[^#].*[[:space:]]swap[[:space:]]/s/^/#/' /etc/fstab && \
      echo 'Commented out swap entries in /etc/fstab'; \
    else \
      echo 'No active swap entries found in /etc/fstab'; \
    fi"
  done
  # Check if repo is already cloned or not
  if [ -d "${KUBESPRAY_SRC_DIR}" ]; then
    echo -e "${BLUE}Kubespray already exists, proceeding with next step${RESET}"
  else
    # Clone repo and switch to latest stable release tag
    cd /usr/local/src && sudo git clone https://github.com/kubernetes-sigs/kubespray.git "${KUBESPRAY_SRC_DIR}"
    sudo chown -R ${USER}:${USER} "${KUBESPRAY_SRC_DIR}"
    cd ${KUBESPRAY_SRC_DIR}
    git checkout "tags/$(get_latest_release "kubernetes-sigs/kubespray")"
    cd ..
    sudo chown -R ${USER}:${USER} "${KUBESPRAY_SRC_DIR}"
  fi
  python3 -m venv "${PYTHON_ENV_DIR}" && source "${PYTHON_ENV_DIR}"/bin/activate
  pip install -r "${KUBESPRAY_SRC_DIR}"/requirements.txt
}

# Step 3: Kernel modules + sysctl tuning
setup_kernel_tuning () {
  for CLUSTER_NODE_IP in ${CLUSTER_NODES_IPS[@]}; do
    ssh ${USER}@${CLUSTER_NODE_IP} "sudo bash -s" << 'REMOTE_EOF'
set -e
MODULES=(br_netfilter nvme_tcp ext4 xfs)
MODULES_FILE="/etc/modules-load.d/homelab-k8s.conf"
SYSCTL_FILE="/etc/sysctl.d/99-homelab-k8s.conf"

echo "# Managed by install-k8s.sh" > "${MODULES_FILE}"
for mod in "${MODULES[@]}"; do
  modprobe "${mod}" 2>/dev/null && echo "  loaded: ${mod}" || echo "  warning: could not load ${mod} (may be built-in or unavailable)"
  echo "${mod}" >> "${MODULES_FILE}"
done

cat > "${SYSCTL_FILE}" << 'SYSCTL_EOF'
# Managed by install-k8s.sh
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 4096
net.netfilter.nf_conntrack_max = 131072
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
fs.aio-max-nr = 1048576
vm.nr_hugepages = 1024
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 8192
SYSCTL_EOF

sysctl --system
REMOTE_EOF
  done
}

# Step 4: Prepare Kubespray
setup_kubespray () {
  # Create cluster directory
  cp -rfp "${KUBESPRAY_SRC_DIR}"/inventory/sample "${KUBESPRAY_INV_DIR}"
  local nodes_count=$(echo "${#CLUSTER_NODES_IPS[@]}")
  # Prepare Ansible inventory file
  echo -e "${BLUE}Preparing the inventory file for ${nodes_count} control plane nodes${RESET}"

  echo "[kube_control_plane]" >> "${KUBESPRAY_INV_FILE}"
  counter=1
  for ip in "${CLUSTER_NODES_IPS[@]}"; do
      echo -e "node${counter} ansible_host=${ip} ip=${ip} etcd_member_name=etcd${counter}" >> "${KUBESPRAY_INV_FILE}"
      ((counter++))
  done
  echo -e "[etcd:children]\nkube_control_plane\n" >> "${KUBESPRAY_INV_FILE}"

  echo "[kube_node]" >> "${KUBESPRAY_INV_FILE}"
  counter=1
  for ip in "${CLUSTER_NODES_IPS[@]}"; do
      echo -e "node${counter} ansible_host=${ip} ip=${ip}" >> "${KUBESPRAY_INV_FILE}"
      ((counter++))
  done

  # etcd config
  if [[ "${ETCD_MODE}" == "host" || "${ETCD_MODE}" == "kubeadm" ]]; then
    sed -i "s/^etcd_deployment_type: .*/etcd_deployment_type: ${ETCD_MODE}/" "${ETCD_CONFIG_FILE}"
  else
      echo "Invalid ETCD_MODE: ${ETCD_MODE}. Must be 'host' or 'kubeadm'."
      exit 1
  fi

  # cni config: Kubespray never installs a CNI (kube_network_plugin: cni), so kube-proxy and
  # nodelocaldns are disabled. Bring your own CNI separately (e.g. Cilium with kubeProxyReplacement).
  sed -i "s/^kube_network_plugin: .*/kube_network_plugin: cni/" "${CLUSTER_CONFIG_FILE}"
  sed -i "s/^kube_owner: .*/kube_owner: root/" "${CLUSTER_CONFIG_FILE}"
  set_yaml_var "kube_proxy_remove" "true" "${CLUSTER_CONFIG_FILE}"
  set_yaml_var "enable_nodelocaldns" "false" "${CLUSTER_CONFIG_FILE}"
  set_yaml_var "kube_resolv_conf" "/run/systemd/resolve/resolv.conf" "${CLUSTER_CONFIG_FILE}"
  echo -e "${YELLOW}kube-proxy and nodelocaldns are disabled. Make sure the CNI you install separately is configured to replace their functionality (e.g. Cilium's kubeProxyReplacement).${RESET}"

  # kubeadm cert auto-renewal config
  if [[ "${AUTO_RENEW_CERTIFICATES}" == "true" || "${AUTO_RENEW_CERTIFICATES}" == "false" ]]; then
      sed -i "s/^auto_renew_certificates: .*/auto_renew_certificates: ${AUTO_RENEW_CERTIFICATES}/" "${CLUSTER_CONFIG_FILE}"
  else
      echo "Invalid AUTO_RENEW_CERTIFICATES: ${AUTO_RENEW_CERTIFICATES}. Must be 'true' or 'false'."
      exit 1
  fi

  # kubelet imageMaximumGCAge config (optional, only added if KUBELET_IMAGE_MAXIMUM_GC_AGE is set)
  if [[ -n "${KUBELET_IMAGE_MAXIMUM_GC_AGE}" ]]; then
      if ! grep -q "imageMaximumGCAge:" "${CLUSTER_CONFIG_FILE}"; then
          printf 'kubelet_config_extra_args:\n  imageMaximumGCAge: "%s"\n' "${KUBELET_IMAGE_MAXIMUM_GC_AGE}" >> "${CLUSTER_CONFIG_FILE}"
      fi
  fi

  # Pod Security Admission default config (optional, only added if PSA_DEFAULT_LEVEL is set).
  # enforce/audit/warn all share the same level for simplicity.
  if [[ -n "${PSA_DEFAULT_LEVEL}" ]]; then
      set_yaml_var "kube_apiserver_admission_control_config_file" "true" "${CLUSTER_CONFIG_FILE}"
      set_yaml_var "kube_apiserver_enable_admission_plugins" '["PodSecurity"]' "${CLUSTER_CONFIG_FILE}"
      set_yaml_var "kube_pod_security_use_default" "true" "${CLUSTER_CONFIG_FILE}"
      set_yaml_var "kube_pod_security_default_enforce" "${PSA_DEFAULT_LEVEL}" "${CLUSTER_CONFIG_FILE}"
      set_yaml_var "kube_pod_security_default_audit" "${PSA_DEFAULT_LEVEL}" "${CLUSTER_CONFIG_FILE}"
      set_yaml_var "kube_pod_security_default_warn" "${PSA_DEFAULT_LEVEL}" "${CLUSTER_CONFIG_FILE}"
  fi

  # Pod Security Admission exempted namespaces: kube-system is always exempted explicitly
  local exempt_list
  exempt_list=$(printf '"%s", ' "kube-system" "${PSA_EXEMPT_NAMESPACES[@]}")
  exempt_list="[${exempt_list%, }]"
  set_yaml_var "kube_pod_security_exemptions_namespaces" "${exempt_list}" "${CLUSTER_CONFIG_FILE}"

  # Audit setup
  if [[ -n "${ENABLE_AUDIT}" ]]; then
    if [[ ! -f "${AUDIT_POLICY_FILE}" ]]; then
      echo -e "${RED}${BOLD}${AUDIT_POLICY_FILE} not found.${RESET}"
      exit 1
    fi

    # Pull just the "rules:" list out of the manifest and dedent it.
    local audit_policy_rules
    audit_policy_rules=$(awk '/^rules:/{flag=1; next} flag' "${AUDIT_POLICY_FILE}" | sed 's/^  //')

    set_yaml_var "kubernetes_audit" "true" "${CLUSTER_CONFIG_FILE}"
    set_yaml_var "audit_log_maxage" "${AUDIT_LOG_MAXAGE}" "${CLUSTER_CONFIG_FILE}"
    set_yaml_var "audit_log_maxbackups" "${AUDIT_LOG_MAXBACKUPS}" "${CLUSTER_CONFIG_FILE}"
    set_yaml_var "audit_log_maxsize" "${AUDIT_LOG_MAXSIZE}" "${CLUSTER_CONFIG_FILE}"
    set_yaml_block "audit_policy_custom_rules" "${audit_policy_rules}" "${CLUSTER_CONFIG_FILE}"
  fi

  echo -e "[defaults]\nroles_path = "${KUBESPRAY_SRC_DIR}"/roles" > ~/.ansible.cfg
}

# Step 5: Install Kubernetes
install_kubernetes () {
  # Install kubernetes cluster using Ansible Playbook
  ansible-playbook -i "${KUBESPRAY_INV_FILE}" -u ${USER} --become --become-user=root "${KUBESPRAY_SRC_DIR}"/cluster.yml
  echo -e "${BLUE}${BOLD}Cluster has been installed${RESET}" && sleep 5
  # Test Kubernetes cluster installation
  echo -e "${BLUE}Validating the installed kubernetes cluster..${RESET}"
  sudo su -c "kubectl version"
  sudo su -c "kubectl get nodes -o wide"
  sudo su -c "kubectl get all -A"
  for CLUSTER_NODE_IP in "${CLUSTER_NODES_IPS[@]}"
  do
    ssh -t "${CLUSTER_NODE_IP}" "sudo su -c 'curl -k https://"${CLUSTER_NODE_IP}":6443/readyz?verbose'"
  done
  # Exit Python venv
  deactivate
  # Enable kubectl bash completion and set k as alias
  echo 'source <(kubectl completion bash)' >> ~/.bashrc
  echo 'alias k=kubectl' >> ~/.bashrc
  echo 'complete -F __start_kubectl k' >> ~/.bashrc
  sudo cp -ra /root/.kube ~/.kube && sudo chown -R $UID:$UID ~/.kube
}

# Main function
main() {
  echo -e "\n${BLUE}${BOLD}█▒▒▒▒▒ INIT CONNECTIONS ▒▒▒▒▒█${RESET}\n"
  init_connections
  echo -e "\n${BLUE}${BOLD}██▒▒▒▒ DOWNLOADING DEPENDENCIES ▒▒▒▒██${RESET}\n"
  download_dependencies
  echo -e "\n${BLUE}${BOLD}███▒▒▒ TUNING KERNEL / SYSCTLS ▒▒▒███${RESET}\n"
  setup_kernel_tuning
  echo -e "\n${BLUE}${BOLD}████▒▒ SETTING UP KUBESPRAY ▒▒████${RESET}\n"
  setup_kubespray
  echo -e "\n${BLUE}${BOLD}█████▒ INSTALLING KUBERNETES ▒█████${RESET}\n"
  install_kubernetes
  echo -e "\n${BLUE}${BOLD}██████ KUBERNETES HAS BEEN INSTALLED SUCCESSFULLY ██████${RESET}\n"
}

main