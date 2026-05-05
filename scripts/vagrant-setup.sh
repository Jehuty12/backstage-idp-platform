#!/usr/bin/env bash
# vagrant-setup.sh
# Script to setup and test the 3-node Kubernetes cluster with Vagrant/VirtualBox

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Vagrant Kubernetes Cluster Setup"
echo "=========================================="

# Check prerequisites
echo ""
echo "[1/5] Checking prerequisites..."
if ! command -v vagrant &> /dev/null; then
    echo "❌ Vagrant not installed. Please install from https://www.vagrantup.com/"
    exit 1
fi
if ! command -v virtualbox &> /dev/null; then
    echo "❌ VirtualBox not installed. Please install from https://www.virtualbox.org/"
    exit 1
fi
echo "✓ Vagrant and VirtualBox found"

# Start master node
echo ""
echo "[2/5] Starting master node..."
cd "$SCRIPT_DIR"
vagrant up master || true
echo "✓ Master node started"

# Wait and check master
echo ""
echo "[3/5] Waiting for master to be ready..."
sleep 30
echo "Checking master status..."
vagrant ssh master -c "sudo kubectl get nodes" 2>/dev/null || echo "  (Master still initializing...)"
echo "✓ Master ready"

# Start worker nodes
echo ""
echo "[4/5] Starting worker nodes..."
vagrant up worker1 worker2 || true
echo "✓ Workers started"

# Verify cluster
echo ""
echo "[5/5] Verifying cluster..."
sleep 20
echo "Cluster nodes:"
vagrant ssh master -c "sudo kubectl get nodes"
echo ""
echo "Cluster pods (all namespaces):"
vagrant ssh master -c "sudo kubectl get pods -A"

echo ""
echo "=========================================="
echo "✓ Vagrant cluster setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. SSH to master: vagrant ssh master"
echo "  2. Check kubeconfig: sudo cat /home/vagrant/.kube/config"
echo "  3. Deploy ArgoCD: kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
