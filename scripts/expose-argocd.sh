#!/bin/bash
set -euo pipefail

# Expose argocd-server as NodePort and print the nodePort
kubectl -n argocd patch svc argocd-server -p '{"spec":{"type":"NodePort"}}'
NODEPORT=$(kubectl -n argocd get svc argocd-server -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}')
echo "ARGOCD_NODEPORT=${NODEPORT}"
kubectl -n argocd get svc argocd-server -o wide
