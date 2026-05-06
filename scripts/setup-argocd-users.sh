#!/bin/bash
set -euo pipefail

ARGOCD_NS="argocd"
MANIFEST="${1:-/vagrant/infrastructure/argocd/users-rbac.yaml}"

echo "=== Applying ArgoCD RBAC Configuration ==="
kubectl apply -f "$MANIFEST"

echo ""
echo "=== Getting ArgoCD server pod ==="
ARGOCD_POD=$(kubectl -n $ARGOCD_NS get pod -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].metadata.name}')
if [ -z "$ARGOCD_POD" ]; then
  echo "ERROR: argocd-server pod not found!"
  exit 1
fi
echo "Using pod: $ARGOCD_POD"

echo ""
echo "=== Creating ArgoCD Local Users ==="

# Define users and their passwords
declare -A USERS
USERS[admin]="AdminPass123!"
USERS[superviseur]="SuperPass456!"
USERS[dev]="DevPass789!"
USERS[bob]="BobReadOnly!@"

# Function to set user password via argocd-util inside pod
set_user_password() {
  local username=$1
  local password=$2
  
  echo "Setting password for user: $username"
  
  # Use argocd-util inside the pod to hash the password
  # Then patch the argocd-secret
  local hash=$(kubectl -n $ARGOCD_NS exec "$ARGOCD_POD" -- \
    argocd-util account bcrypt --password "$password")
  
  # Patch the argocd-secret with the new password hash
  kubectl -n $ARGOCD_NS patch secret argocd-secret --type merge \
    -p "{\"data\":{\"accounts.${username}.password\":\"$(echo -n "$hash" | base64 -w 0)\"}}"
  
  echo "  ✓ $username password set"
}

# Set passwords for all users
for user in "${!USERS[@]}"; do
  set_user_password "$user" "${USERS[$user]}"
done

echo ""
echo "=== Restarting ArgoCD Server ==="
kubectl -n $ARGOCD_NS rollout restart deployment/argocd-server
kubectl -n $ARGOCD_NS rollout status deployment/argocd-server --timeout=5m

echo ""
echo "=== ✓ ArgoCD Users and RBAC Configured ==="
echo ""
echo "User Credentials:"
for user in "${!USERS[@]}"; do
  echo "  $user: ${USERS[$user]}"
done
echo ""
echo "Access URL: https://192.168.56.10:31200"
echo ""
echo "=== RBAC Policies (sample) ==="
kubectl -n $ARGOCD_NS get cm argocd-rbac-cm -o jsonpath='{.data.policy\.csv}' | head -15
