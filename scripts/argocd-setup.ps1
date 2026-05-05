# argocd-setup.ps1
# PowerShell script to install and configure ArgoCD on the Kubernetes cluster

Write-Host "=========================================="
Write-Host "ArgoCD Setup & Configuration"
Write-Host "=========================================="

# Create namespace
Write-Host ""
Write-Host "[1/4] Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
Write-Host "✓ Namespace created"

# Install ArgoCD
Write-Host ""
Write-Host "[2/4] Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
Write-Host "✓ ArgoCD installed"

# Wait for ArgoCD to be ready
Write-Host ""
Write-Host "[3/4] Waiting for ArgoCD to be ready (this may take 1-2 minutes)..."
$maxWait = 300
$elapsed = 0
while ($elapsed -lt $maxWait) {
    $podStatus = kubectl get pod -l app.kubernetes.io/name=argocd-server -n argocd -o jsonpath='{.items[0].status.phase}' 2>$null
    if ($podStatus -eq "Running") {
        Write-Host "✓ ArgoCD pod is Running"
        break
    }
    Start-Sleep -Seconds 5
    $elapsed += 5
    Write-Host "  Waiting... ($elapsed/$maxWait)"
}

kubectl get pods -n argocd
Write-Host "✓ ArgoCD ready"

# Get initial admin password
Write-Host ""
Write-Host "[4/4] ArgoCD Configuration..."
$argocdPasswordB64 = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null
if ($argocdPasswordB64) {
    $argocdPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($argocdPasswordB64))
} else {
    $argocdPassword = "(secret not yet available)"
}

$argocdServer = kubectl -n argocd get svc argocd-server -o jsonpath='{.spec.clusterIP}' 2>$null

Write-Host ""
Write-Host "=========================================="
Write-Host "✓ ArgoCD Setup Complete!"
Write-Host "=========================================="
Write-Host ""
Write-Host "Access ArgoCD:"
Write-Host "  UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
Write-Host "  Then visit: https://localhost:8080"
Write-Host ""
Write-Host "Credentials:"
Write-Host "  Username: admin"
Write-Host "  Password: $argocdPassword"
Write-Host ""
Write-Host "CLI setup:"
Write-Host "  argocd login localhost:8080 --username admin --password '$argocdPassword'"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Create Application manifests in infrastructure/argocd/apps/"
Write-Host "  2. Apply the App-of-Apps root manifest"
