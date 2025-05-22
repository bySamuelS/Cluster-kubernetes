#!/bin/bash

set -e

echo "🚀 Déploiement de Prometheus + Grafana sur le cluster Kubernetes..."

### 1. Vérification de Helm
if ! command -v helm &> /dev/null; then
    echo "🔧 Helm non trouvé. Installation en cours..."
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
else
    echo "✅ Helm est déjà installé"
fi

### 2. Ajouter le repo prometheus-community
echo "📦 Ajout du dépôt Helm prometheus-community..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

### 3. Créer le namespace monitoring
echo "📁 Création du namespace monitoring..."
kubectl create namespace monitoring || echo "Namespace déjà existant"

### 4. Installation de la stack kube-prometheus-stack
echo "📡 Installation de kube-prometheus-stack..."
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword='admin123'

### 5. Attente que les pods soient prêts
echo "⏳ Attente que les pods soient prêts (cela peut prendre 1 à 2 minutes)..."
kubectl wait --for=condition=Ready pods --all -n monitoring --timeout=180s

### 6. Port-forward Grafana et Prometheus (facultatif)
echo "🌐 Accès local à Grafana : http://localhost:3000"
echo "     ➤ login : admin"
echo "     ➤ mot de passe : admin123"
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80 &

echo "🌐 Accès local à Prometheus : http://localhost:9090"
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090 &

echo "✅ Monitoring stack déployée avec succès !"

