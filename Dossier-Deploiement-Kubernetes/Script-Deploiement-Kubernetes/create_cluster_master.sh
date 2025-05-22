#!/bin/bash

set +e

# ================================
# SCRIPT POUR REJOINDRE UN CLUSTER KUBERNETES EN TANT QUE WORKER
# ================================


echo "[1/10] ➤ Mise à jour des paquets..."

sudo apt update -y && sudo apt upgrade -y



echo "[2/10] ➤ Installation des dépendances..."
sudo apt install -y curl apt-transport-https ca-certificates software-properties-common

echo "[3/10] ➤ Importation des images docker..."
for img in ../Image-Docker-Installation-Kubernetes/*.tar; do
  ctr -n k8s.io images import "$img"
done

echo "[4/10] ➤ Désactivation du swap..."

sudo swapoff -a

sudo sed -i '/ swap / s/^/#/' /etc/fstab



echo "[5/10] ➤ Chargement des modules du noyau..."

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



echo "[6/10] ➤ Installation de containerd..."

sudo apt update -y

sudo apt install -y containerd



echo "[7/10] ➤ Configuration de containerd..."

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd

sudo systemctl enable containerd



echo "[8/10] ➤ Installation de Kubernetes (kubelet, kubeadm, kubectl)..."
K8S_VERSION="1.32"
sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL http://<ip-du-serveur-de-dépot>/depot/apt/apt.kubernetes.io/dists/kubernetes-xenial/Release.gpg | \
    
sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg


####################################################################################################################
## 
## echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg]                                             
## https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | \ 
## sudo tee /etc/apt/sources.list.d/kubernetes.list 
##
####################################################################################################################

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
http://<ip-du-serveur-de-dépot>/depot/apt/apt.kubernetes.io kubernetes-xenial main" | sudo tee /etc/apt/sources.list/kubernetes.list


sudo apt update -y 
###################################################
## sudo apt install -y kubelet kubeadm kubectl 
##
#################################################
for pkg in ../Packages/*.deb; do
  dpkg -i "$pkg"
done

apt install socat
apt --fix-broken install

sudo apt-mark hold kubelet kubeadm kubectl


echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc

echo "[9/10] ➤ Démarrage de kubelet..."

sudo systemctl start kubelet

sudo systemctl enable kubelet




echo "[10/10] ➤ Manipulation à faire..."
echo "Vérification du sandbox en 3.9..."
sudo crictl info | grep sandboxImage
echo "#######################################################################################################"
echo "Si il y a une erreur à l'étape 10/10 alors pause est en version 3.6, exécuter :"
echo "nano /etc/containerd/config.toml"
echo "remplacez la version de pause dans la partie sandbox-image en version 3.9"
echo "#######################################################################################################"
