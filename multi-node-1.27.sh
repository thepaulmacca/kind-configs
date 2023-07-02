#!/bin/sh
set -o errexit

readonly CLUSTER_NAME=multi-node-1.27
# before changing k8s node version, check the kind release pages for node version (https://github.com/kubernetes-sigs/kind/releases) and use the exact image including the digest
readonly NODE_K8S_VERSION=${NODE_K8S_VERSION:-v1.27.3@sha256:3966ac761ae0136263ffdb6cfd4db23ef8a83cba8a463690e98317add2c9ba72}
readonly WAIT_FOR_CONTROLPLANE=60s

# create a multi-node cluster
kind create cluster --name "$CLUSTER_NAME" --config=configs/multi-node-1.27.yaml --image "kindest/node:$NODE_K8S_VERSION" --wait $WAIT_FOR_CONTROLPLANE

echo "Installing ArgoCD 🚀..."

# install argocd
kubectl create namespace argocd

kubectl apply --namespace argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=5m

echo "Waiting for ArgoCD Server to become ready ⌛..."

echo "Installing NGINX ingress controller 🚦..."

# install NGINX ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "Waiting for NGINX ingress controller to become ready ⌛..."

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=5m

echo "Applying helmfile ⌛..."

helmfile apply

echo "Cluster setup complete! ✅"
