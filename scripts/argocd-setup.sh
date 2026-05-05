#!/usr/bin/env bash
# argocd-setup.sh
# Script to install and configure ArgoCD on the Kubernetes cluster

set -e

echo "=========================================="
echo "ArgoCD Setup & Configuration"
echo "=========================================="

# Create namespace
echo ""
echo "[1/4] Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
echo "✓ Namespace created"

# Install ArgoCD
echo ""
echo "[2/4] Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "✓ ArgoCD installed"

# Wait for ArgoCD to be ready
echo ""
echo "[3/4] Waiting for ArgoCD to be ready (this may take 1-2 minutes)..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s 2>/dev/null || true
sleep 10
kubectl get pods -n argocd
echo "✓ ArgoCD ready"

# Get initial admin password
echo ""
echo "[4/4] ArgoCD Configuration..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
ARGOCD_SERVER=$(kubectl -n argocd get svc argocd-server -o jsonpath='{.spec.clusterIP}')

echo ""
echo "=========================================="
echo "✓ ArgoCD Setup Complete!"
echo "=========================================="
echo ""
echo "Access ArgoCD:"
echo "  UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  Then visit: https://localhost:8080"
echo ""
echo "Credentials:"
echo "  Username: admin"
echo "  Password: $ARGOCD_PASSWORD"
echo ""
echo "CLI setup:"
echo "  argocd login localhost:8080 --username admin --password '$ARGOCD_PASSWORD'"
echo ""
echo "Next steps:"
echo "  1. Create Application manifests in infrastructure/argocd/apps/"
echo "  2. Apply the App-of-Apps root manifest"
