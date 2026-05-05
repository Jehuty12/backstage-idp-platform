#!/usr/bin/env bash
# setup-kubeadm-master.sh
# Initialize kubeadm cluster on master node

set -e

echo "Initializing Kubernetes cluster with kubeadm..."

# Initialize the control plane
sudo kubeadm init \
  --apiserver-advertise-address=192.168.56.10 \
  --pod-network-cidr=192.168.0.0/16 \
  --kubernetes-version=v1.31.14

# Configure kubeconfig for vagrant user
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config

echo ""
echo "✓ Kubernetes cluster initialized!"
echo ""
echo "Next: Install CNI (Calico)"

# Install Calico CNI
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Generate join command for workers
echo ""
echo "Creating join script for workers..."
kubeadm token create --print-join-command > /vagrant/join.sh
chmod +x /vagrant/join.sh

echo ""
echo "✓ Setup complete!"
echo ""
kubectl get nodes
