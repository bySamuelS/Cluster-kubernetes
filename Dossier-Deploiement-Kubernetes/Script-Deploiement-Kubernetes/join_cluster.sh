#!/bin/bash

set -e

# ================================
# SCRIPT POUR REJOINDRE UN CLUSTER KUBERNETES EN TANT QUE WORKER
# ================================

echo "[1/9] ➤ Mise à jour des paquets..."
sudo apt update -y && sudo apt upgrade -y

echo "[2/9] ➤ Installation des dépendances..."
sudo apt install -y curl apt-transport-https ca-certificates software-properties-common

echo "[3/9] ➤ Désactivation du swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "[4/9] ➤ Chargement des modules du noyau..."
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

echo "[5/9] ➤ Installation de containerd..."
sudo apt update -y
sudo apt install -y containerd

echo "[6/9] ➤ Configuration de containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "[7/9] ➤ Installation de Kubernetes (kubelet, kubeadm, kubectl)..."
K8S_VERSION="1.32"
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update -y
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[8/9] ➤ Démarrage de kubelet..."
sudo systemctl start kubelet
sudo systemctl enable kubelet

echo "[9/9] ➤ Rejoindre le cluster master Kubernetes..."
sudo kubeadm join 192.168.122.250:6443 \
    --token c5fk9x.i6lat72mfhj1hbsc \
    --discovery-token-ca-cert-hash sha256:20c65f792df1edd7407d086043e9702178d838f5561a90f9f491231e141aa602

echo "✅ Le noeud worker a rejoint le cluster avec succès."